# Sistema Unificado de Estados UI - Design Doc

## Goal

Modernizar el manejo de estados UI (loading, success, error, empty) en todo el proyecto Flutter, creando un sistema reutilizable y consistente que reemplace los patrones ad-hoc actuales.

## Decisiones de Diseno

| Aspecto | Decision |
|---------|----------|
| Estado en providers | `ViewStateMixin` con enum `ViewState` |
| Widget wrapper | `StateView<T>` con `AnimatedSwitcher` (fade) |
| Notificaciones | `AppOverlay` custom (eliminar Fluttertoast + SnackBar) |
| Loading listas | Shimmer/Skeleton para listas y cards |
| Loading acciones | Loader minimalista para acciones puntuales |
| Transiciones | `AnimatedSwitcher` fade solo en cambios de estado principales |
| Migracion | Incremental: sistema base + piloto FuelRed |

## Arquitectura

### Capa 1: ViewStateMixin (Provider)

```dart
enum ViewState { loading, content, error, empty }

mixin ViewStateMixin on ChangeNotifier {
  ViewState _viewState = ViewState.loading;
  String? _errorMessage;

  ViewState get viewState => _viewState;
  String? get errorMessage => _errorMessage;

  void setLoading() { _viewState = ViewState.loading; _errorMessage = null; notifyListeners(); }
  void setContent() { _viewState = ViewState.content; _errorMessage = null; notifyListeners(); }
  void setError(String msg) { _viewState = ViewState.error; _errorMessage = msg; notifyListeners(); }
  void setEmpty() { _viewState = ViewState.empty; _errorMessage = null; notifyListeners(); }
}
```

### Capa 2: StateView Widget

```dart
StateView<MyProvider>(
  onLoading: () => ShimmerList(),
  onError: (msg, retry) => ErrorCard(message: msg, onRetry: retry),
  onEmpty: () => EmptyState(icon: Icons.inbox, text: 'Sin datos'),
  onContent: (provider) => MyContentWidget(provider),
)
```

- Usa `AnimatedSwitcher` con `FadeTransition` para cambios suaves
- Acepta builders para cada estado
- El shimmer se usa para listas, `MinimalLoader` para acciones

### Capa 3: AppOverlay (Notificaciones)

```dart
AppOverlay.success(context, 'Despacho autorizado');
AppOverlay.error(context, 'Error al conectar');
AppOverlay.warning(context, 'Sin conexion WS');
AppOverlay.info(context, 'Sincronizando...');
```

- Usa `Overlay.of(context)` (independiente de Scaffold)
- Slide-in desde arriba + fade
- Auto-dismiss 3s
- 4 niveles: success (verde), error (rojo), warning (naranja), info (azul)

## Componentes Nuevos

| Archivo | Componente |
|---------|------------|
| `lib/Components/state/view_state.dart` | Enum + Mixin |
| `lib/Components/state/state_view.dart` | Widget wrapper |
| `lib/Components/state/shimmer_card.dart` | Skeleton card |
| `lib/Components/state/shimmer_list.dart` | Skeleton lista |
| `lib/Components/state/minimal_loader.dart` | Spinner sutil |
| `lib/Components/state/error_card.dart` | Error inline |
| `lib/Components/state/empty_state.dart` | Estado vacio |
| `lib/Components/overlay/app_overlay.dart` | Toast flotante |

## Migracion Piloto: FuelRed

1. `FuelRedProvider` adopta `ViewStateMixin`
2. `FuelRedPage` se envuelve en `StateView`
3. `_RfidScanSheet` reemplaza `String _phase` por enum tipado
4. SnackBars y Fluttertoast se reemplazan por `AppOverlay`

## Fuera de Alcance (por ahora)

- Migrar otras screens (Facturas, Transacciones, etc.)
- Cambios en logica de negocio de providers
- Navegacion, temas, estructura de carpetas
