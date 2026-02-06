---
description: Implementar endpoint de polling centralizado en YAM para estados de dispensadores
---

# Polling Centralizado para Estados de Dispensadores

## Problema Actual

Los handhelds hacen polling **directamente** al API de la consola (Horustec) cada 1.5 segundos. Esto causa:

1. **Saturación del API**: Si hay N dispositivos, hay N llamadas cada 1.5s
2. **HTTP 500 frecuentes**: La consola no soporta la carga
3. **Respuestas lentas**: El API tarda en responder
4. **Estados inconsistentes**: Respuestas desordenadas causan confusión

## Solución Propuesta

Crear un **endpoint proxy con cache** en YAM que:
1. Sea el ÚNICO que consulte la consola
2. Cachee el resultado por 1.5-2 segundos
3. Los handhelds consulten a YAM en lugar de la consola

## Arquitectura

```
┌──────────────┐                    ┌──────────────┐
│    YAM       │ ─── poll ────────→ │   Consola    │
│  (tu server) │ ← solo cuando     │  (Horustec)  │
│              │   cache expira    │              │
└──────┬───────┘                    └──────────────┘
       │
       │ GET /api/dispensers/status (rápido, estable)
       ▼
┌──────────────────────────────────────────────────┐
│   Handheld A    │    Handheld B    │    PC      │
└──────────────────────────────────────────────────┘
```

## Implementación en YAM (C#)

### 1. Modelo de Datos

```csharp
public class DispenserStatus
{
    public int Number { get; set; }
    public string Key { get; set; }
    public string Description { get; set; }
    public string Status { get; set; }
    public string ActiveHose { get; set; }
    public List<DispenserHose> Hoses { get; set; }
}

public class DispenserHose
{
    public int Number { get; set; }
    public string Key { get; set; }
    public string Status { get; set; }
    public string Description { get; set; }
    public decimal TotalVolume { get; set; }
    public decimal TotalAmount { get; set; }
}
```

### 2. Servicio de Cache

```csharp
public interface IDispenserStatusService
{
    Task<List<DispenserStatus>> GetStatusAsync();
}

public class DispenserStatusService : IDispenserStatusService
{
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IMemoryCache _cache;
    private readonly ILogger<DispenserStatusService> _logger;
    
    private const string CacheKey = "DispensersStatus";
    private const int CacheSeconds = 2; // Tiempo de vida del cache
    
    // URL de la consola Horustec
    private readonly string _horustecBaseUrl;

    public DispenserStatusService(
        IHttpClientFactory httpClientFactory,
        IMemoryCache cache,
        IConfiguration config,
        ILogger<DispenserStatusService> logger)
    {
        _httpClientFactory = httpClientFactory;
        _cache = cache;
        _logger = logger;
        _horustecBaseUrl = config["Horustec:BaseUrl"]; 
        // Ejemplo: "https://costarica-demo-9010.asptienda.com/api"
    }

    public async Task<List<DispenserStatus>> GetStatusAsync()
    {
        // Intentar obtener del cache
        if (_cache.TryGetValue(CacheKey, out List<DispenserStatus> cached))
        {
            _logger.LogDebug("Dispensers status returned from cache");
            return cached;
        }

        // Cache expirado o vacío: consultar la consola
        _logger.LogInformation("Cache expired, fetching from Horustec...");
        
        try
        {
            var client = _httpClientFactory.CreateClient();
            client.Timeout = TimeSpan.FromSeconds(10);
            
            var response = await client.GetAsync(
                $"{_horustecBaseUrl}/Manager/GetDispensersStatus");
            
            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("Horustec returned {StatusCode}", response.StatusCode);
                // Si falla, intentar devolver cache viejo (si existe)
                return cached ?? new List<DispenserStatus>();
            }

            var json = await response.Content.ReadAsStringAsync();
            var result = JsonSerializer.Deserialize<List<DispenserStatus>>(json);
            
            // Guardar en cache
            var cacheOptions = new MemoryCacheEntryOptions()
                .SetAbsoluteExpiration(TimeSpan.FromSeconds(CacheSeconds));
            _cache.Set(CacheKey, result, cacheOptions);
            
            _logger.LogInformation("Fetched {Count} dispensers from Horustec", result?.Count ?? 0);
            return result ?? new List<DispenserStatus>();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching from Horustec");
            return cached ?? new List<DispenserStatus>();
        }
    }
}
```

### 3. Controller

```csharp
[ApiController]
[Route("api/[controller]")]
public class DispensersController : ControllerBase
{
    private readonly IDispenserStatusService _service;

    public DispensersController(IDispenserStatusService service)
    {
        _service = service;
    }

    /// <summary>
    /// Obtiene el estado de todos los dispensadores.
    /// Usa cache de 2 segundos para evitar saturar la consola.
    /// </summary>
    [HttpGet("status")]
    public async Task<IActionResult> GetStatus()
    {
        var result = await _service.GetStatusAsync();
        return Ok(result);
    }
}
```

### 4. Registro en Program.cs / Startup.cs

```csharp
// En Program.cs (.NET 6+)
builder.Services.AddMemoryCache();
builder.Services.AddHttpClient();
builder.Services.AddSingleton<IDispenserStatusService, DispenserStatusService>();

// En appsettings.json
{
  "Horustec": {
    "BaseUrl": "https://costarica-demo-9010.asptienda.com/api"
  }
}
```

## Implementación en Flutter (App Móvil)

### Modificar ConsoleApiHelper

Cambiar el método `getDispensersStatus` para consultar YAM en lugar de Horustec:

```dart
// Antes:
static Future<List<DispenserStatus>> getDispensersStatus() async {
  final uri = Uri.parse('${Constans.baseUrlHorustec}Manager/GetDispensersStatus');
  // ...
}

// Después:
static Future<List<DispenserStatus>> getDispensersStatus() async {
  // Consultar YAM en lugar de Horustec directamente
  final uri = Uri.parse('${Constans.baseUrlYam}/api/dispensers/status');
  // ...
}
```

O mantener ambos y elegir según configuración:

```dart
static Future<List<DispenserStatus>> getDispensersStatus() async {
  final useProxy = Constans.useYamProxy; // true/false en config
  
  final uri = useProxy
    ? Uri.parse('${Constans.baseUrlYam}/api/dispensers/status')
    : Uri.parse('${Constans.baseUrlHorustec}Manager/GetDispensersStatus');
  // ...
}
```

## Beneficios

| Métrica | Antes (directo) | Después (via YAM) |
|---------|-----------------|-------------------|
| **Llamadas a consola (2 dispositivos)** | ~80/min | ~40/min |
| **Llamadas a consola (5 dispositivos)** | ~200/min | ~40/min |
| **Llamadas a consola (sin actividad)** | 0/min | 0/min |
| **Estabilidad** | Depende de Horustec | Depende de YAM (tu servidor) |
| **Tiempo de respuesta** | 1-3 segundos | <100ms (cache) |

## Notas Importantes

1. **El cache es por tiempo, no por cantidad de peticiones**: Aunque 10 dispositivos pidan al mismo tiempo, solo se hace UNA llamada a la consola si el cache está expirado.

2. **Resilencia**: Si la consola falla, YAM devuelve el último estado válido del cache.

3. **ON-DEMAND**: Si nadie pide datos, YAM no hace polling. El polling solo ocurre cuando:
   - Un cliente pide datos Y
   - El cache está expirado (>2 segundos)

4. **Configuración**: El tiempo de cache (2 segundos) puede ajustarse según necesidades.

## Próximos Pasos

1. [ ] Implementar el servicio en YAM
2. [ ] Agregar el endpoint `/api/dispensers/status`
3. [ ] Probar con Postman/Insomnia
4. [ ] Modificar la app Flutter para usar el nuevo endpoint
5. [ ] Probar en campo con múltiples dispositivos
