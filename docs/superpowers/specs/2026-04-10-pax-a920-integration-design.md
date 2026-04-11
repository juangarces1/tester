# PAX A920 Web Service Integration

**Date:** 2026-04-10
**Status:** Approved
**Scope:** Flutter app + .NET backend (SQLSan DB)

## Context

The project is a Flutter fuel station management app (FuelRed) with a .NET 8 backend (EF Core + SQL Server in Docker). The app manages invoices, payment methods, and cash register closings.

BAC Credomatic provides PAX A920 terminals that expose an HTTP Web Service on port 8080 over WiFi. When the financial app is open on the terminal, any device on the same network can trigger sales, voids, and batch closings via simple HTTP GET requests.

Currently, card payments are recorded manually in the payment form (selecting BAC/BN/Scotia/DAV) without communicating with the terminal. This integration automates the terminal interaction.

## Requirements

1. When the cashier taps "Grabar" (save invoice) and there is a card payment amount > 0, send a sale command to the PAX terminal before saving
2. Support three PAX operations: **venta** (sale), **anulacion** (void), **cierre** (batch close)
3. Store all PAX response data in a new `TransaccionPax` table in SQLSan
4. Support multiple PAX terminals, each associated with a datafono/bank
5. Add IP and port fields to the existing `Datafono` model
6. Integrate void from invoice detail / transaction history
7. Integrate batch close into the existing Cierre Datafonos screen

## Architecture

### PAX Web Service API (provided by terminal)

Base URL: `http://{ip}:{port}`

| Operation | URL | Key Params |
|-----------|-----|------------|
| Venta | `/venta?monto={n}&tamanoLinea=42&delimitador=\|` | monto (no decimals: 10.00 = 1000), propina, impuesto, timeout |
| Anulacion | `/anulacion?recibo={n}&tamanoLinea=42&delimitador=\|` | recibo (invoice number from prior sale) |
| Cierre | `/cierre?tamanoLinea=42&delimitador=\|` | tamanoLinea, delimitador |

Response: JSON with RESPCODE ("00" = approved), AUTORIZACION, STAN, PANMASKED, RRN, RECIBO, TICKET, TxnId, and 20+ other fields. See PAX manual v8 for full spec.

### Database Changes (SQLSan)

**ALTER TABLE Datafono** - add columns:
```sql
ALTER TABLE Datafono ADD Ip VARCHAR(45) NULL;
ALTER TABLE Datafono ADD Puerto INT NULL DEFAULT 8080;
```

**CREATE TABLE TransaccionPax:**
```sql
CREATE TABLE TransaccionPax (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    IdFactura BIGINT NULL,
    IdCierre INT NULL,
    IdDatafono SMALLINT NULL,
    RespCode VARCHAR(10) NULL,
    Autorizacion VARCHAR(50) NULL,
    Stan VARCHAR(20) NULL,
    PanMasked VARCHAR(30) NULL,
    Rrn VARCHAR(30) NULL,
    Recibo VARCHAR(20) NULL,
    TerminalId VARCHAR(20) NULL,
    MerchantId VARCHAR(20) NULL,
    CardHolder VARCHAR(100) NULL,
    IssuerName VARCHAR(50) NULL,
    PosEntryMode VARCHAR(10) NULL,
    CardHash VARCHAR(200) NULL,
    TotalAmount DECIMAL(18,2) NULL,
    BaseAmount DECIMAL(18,2) NULL,
    TipAmount DECIMAL(18,2) NULL,
    TaxAmount DECIMAL(18,2) NULL,
    Ticket NVARCHAR(MAX) NULL,
    TxnId VARCHAR(50) NULL,
    FechaPax VARCHAR(30) NULL,
    Aid VARCHAR(50) NULL,
    AppLabel VARCHAR(50) NULL,
    Arqc VARCHAR(50) NULL,
    Tvr VARCHAR(20) NULL,
    FechaRegistro DATETIME NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (IdDatafono) REFERENCES Datafono(Iddatafono)
);
```

### Backend (.NET 8) Changes

**New model:** `TransaccionPax.cs` in `/Models/` matching the table above.

**Add to SQLSanContext:** `DbSet<TransaccionPax> TransaccionesPax`

**Update model:** `Datafono.cs` - add `Ip` and `Puerto` properties.

**New controller:** `TransaccionesPaxController.cs`
- `POST api/transaccionespax` - Save PAX transaction
- `GET api/transaccionespax/{idFactura}` - Get by invoice ID
- `GET api/transaccionespax/cierre/{idCierre}` - List by closing ID

### Flutter Changes

#### New Files

**`lib/services/pax_service.dart`** - HTTP client for PAX terminal communication:
- `Future<PaxResponse> venta(String ip, int puerto, int monto, {int? impuesto, int? propina})`
- `Future<PaxResponse> anulacion(String ip, int puerto, String recibo)`
- `Future<PaxResponse> cierre(String ip, int puerto)`
- Uses Dio with 60s timeout (cashier waits for card swipe)
- Parses JSON response into `PaxResponse` model

**`lib/Models/Pax/pax_response.dart`** - PAX JSON response model:
- All fields from the PAX response (RESPCODE, AUTORIZACION, STAN, etc.)
- `bool get isApproved => respCode == '00'`
- `String get errorMessage` - human-readable error from RESPCODE table
- `fromJson` / `toJson`

**`lib/Models/Pax/transaccion_pax.dart`** - Backend-persisted model:
- Mirrors the SQL table structure
- `fromJson` / `toJson` for API communication
- Factory `fromPaxResponse(PaxResponse response, {int? idFactura, int? idCierre, int? idDatafono})`

#### Modified Files

**`lib/Models/FuelRed/datafono.dart`** - Add `ip` and `puerto` fields.

**`lib/helpers/api_helper.dart`** - New endpoints:
- `postTransaccionPax(TransaccionPax tx)` - Save to backend
- `getTransaccionesPaxByFactura(int idFactura)` - Fetch by invoice
- `getTransaccionesPaxByCierre(int idCierre)` - Fetch by closing

**Invoice save flow** (wherever "Grabar" is handled):
- Before saving, check if card payment amount > 0
- Look up the associated datafono's IP/port
- Call `PaxService.venta(ip, puerto, monto)`
- Show progress overlay while waiting
- On RESPCODE=00: save invoice + save TransaccionPax to backend
- On failure: show error dialog with PAX error message, allow retry or payment change

**`lib/Screens/CierreDatafonos/cierre_datafonos_screen.dart`**:
- Add "Cierre PAX" button per terminal that has IP configured
- Calls `PaxService.cierre(ip, puerto)`
- Saves response as TransaccionPax
- Can auto-populate monto from PAX response TOTAL_AMOUNT

**Anulacion flow** (new screen or from invoice detail):
- Select a previous PAX transaction (must have RECIBO)
- Call `PaxService.anulacion(ip, puerto, recibo)`
- Save void response as new TransaccionPax with TxnId="ANULACION COMPRA"

## Flow: Sale with PAX

```
Cashier selects payment methods (e.g., Cash 5000 + BAC 3000)
    |
    v
Cashier taps "Grabar"
    |
    v
App detects BAC amount > 0
    |
    v
App looks up BAC datafono -> finds IP 192.168.88.19, port 8080
    |
    v
App shows overlay: "Procesando pago en terminal PAX... Pase la tarjeta"
    |
    v
App sends: GET http://192.168.88.19:8080/venta?monto=300000&tamanoLinea=42&delimitador=|
    |
    v
Customer swipes/taps/inserts card on PAX
    |
    v
PAX returns JSON response
    |
    +-- RESPCODE=00 (Approved)
    |       |
    |       v
    |   Save invoice to backend
    |       |
    |       v
    |   Save TransaccionPax to backend (all PAX fields + idFactura + idCierre)
    |       |
    |       v
    |   Print ticket (optional: use TICKET field from PAX or app's own format)
    |       |
    |       v
    |   Done - show success
    |
    +-- RESPCODE!=00 (Declined/Error)
    |       |
    |       v
    |   Show error: "Transaccion denegada: {message}" 
    |       |
    |       v
    |   Cashier can: retry, change amount, or switch payment method
    |
    +-- Timeout / Connection error
            |
            v
        Show: "No se pudo conectar con la terminal PAX"
            |
            v
        Cashier can: retry or check terminal
```

## RESPCODE Error Table

| Code | Message |
|------|---------|
| 00 | APROBADA |
| 01, 02 | CONSULTE VERBAL |
| 03 | COMERCIO INVALIDO |
| 04 | CAPTURE TARJETA |
| 05 | DENEGADA |
| 12 | TRANSACCION INVALIDA |
| 13 | CANTIDAD INVALIDA |
| 14 | TARJETA INVALIDA |
| 19 | REINTENTE TRANSACCION |
| 21 | SIN TRANSACCIONES |
| 51 | DENEGADA FI |
| 54 | TARJETA VENCIDA |
| 57, 58 | TRANSACCION NO PERMITIDA |
| 94 | TRANSACCION DUPLICADA |
| 96 | ERROR EN SISTEMA |
| NA | SISTEMA NO DISPONIBLE |
| CE | ERROR DE COMUNICACION |
| CONNECT TIMEOUT | POS NO TIENE CONEXION A RED |

Full table available in PAX Manual v8.

## Out of Scope

- PAX terminal configuration/setup (done by BAC technician)
- WiFi network configuration
- PAX terminal firmware updates
- Multi-currency support (all transactions in CRC/colones)
