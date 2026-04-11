# PAX A920 Web Service Integration - Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Integrate PAX A920 payment terminals into the FuelRed invoice flow, enabling automated card sales, voids, and batch closings via HTTP Web Service.

**Architecture:** A `PaxService` in Flutter communicates with the PAX terminal over WiFi (HTTP GET on port 8080). The `goFact()` method in checkout is intercepted before saving: if card payment > 0, we call the PAX first, and only save the invoice on approval. A new `TransaccionPax` table in SQLSan stores all PAX responses. The `Datafono` model is extended with IP/port fields.

**Tech Stack:** Flutter (Dio), .NET 8 (EF Core + SQL Server), PAX A920 HTTP Web Service

---

## File Map

### Backend (.NET) - `/media/juank/ADATA HD710 PRO/FuelRedMobil/FuelRedMobil/`

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `Models/TransaccionPax.cs` | EF entity for PAX transaction data |
| Modify | `Models/Datafono.cs` | Add `Ip` and `Puerto` properties |
| Modify | `Models/SQLSanContext.cs` | Add `DbSet<TransaccionPax>`, update Datafono entity config |
| Create | `Controllers/API/TransaccionesPaxController.cs` | CRUD endpoints for PAX transactions |

### Flutter - `/media/juank/Datos/flutter/tester/lib/`

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `services/pax_service.dart` | HTTP client for PAX terminal (venta, anulacion, cierre) |
| Create | `Models/Pax/pax_response.dart` | Parse PAX JSON response + error code mapping |
| Create | `Models/Pax/transaccion_pax.dart` | Backend-persisted model (mirrors SQL table) |
| Modify | `Models/FuelRed/datafono.dart` | Add `ip` and `puerto` fields |
| Modify | `helpers/api_helper.dart` | Add TransaccionPax endpoints |
| Modify | `Screens/checkout/checkount.dart` | Intercept `goFact()` to call PAX before saving |
| Modify | `Screens/CierreDatafonos/cierre_datafonos_screen.dart` | Add PAX batch close button |

### SQL Script

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `sql/pax_migration.sql` | ALTER Datafono + CREATE TransaccionPax |

---

## Task 1: SQL Migration Script

**Files:**
- Create: `/media/juank/Datos/flutter/tester/sql/pax_migration.sql`

- [ ] **Step 1: Create the SQL migration script**

```sql
-- PAX A920 Integration Migration
-- Run against SQLSan database in Docker

-- 1. Add IP and Port to Datafono table
ALTER TABLE Datafono ADD Ip VARCHAR(45) NULL;
ALTER TABLE Datafono ADD Puerto INT NULL DEFAULT 8080;

-- 2. Create TransaccionPax table
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
    CONSTRAINT FK_TransaccionPax_Datafono FOREIGN KEY (IdDatafono) REFERENCES Datafono(Iddatafono)
);

CREATE INDEX IX_TransaccionPax_IdFactura ON TransaccionPax(IdFactura);
CREATE INDEX IX_TransaccionPax_IdCierre ON TransaccionPax(IdCierre);
```

- [ ] **Step 2: Commit**

```bash
cd /media/juank/Datos/flutter/tester
git add sql/pax_migration.sql
git commit -m "feat(pax): add SQL migration for Datafono IP fields and TransaccionPax table"
```

---

## Task 2: Backend - Update Datafono Model

**Files:**
- Modify: `/media/juank/ADATA HD710 PRO/FuelRedMobil/FuelRedMobil/Models/Datafono.cs`
- Modify: `/media/juank/ADATA HD710 PRO/FuelRedMobil/FuelRedMobil/Models/SQLSanContext.cs:649-660`

- [ ] **Step 1: Add Ip and Puerto to Datafono.cs**

Replace the full file content of `Models/Datafono.cs`:

```csharp
using System;
using System.Collections.Generic;

#nullable disable

namespace FuelRedMobil.Models
{
    public partial class Datafono
    {
        public short Iddatafono { get; set; }
        public short? Idbanco { get; set; }
        public string Nombre { get; set; }
        public string Ip { get; set; }
        public int? Puerto { get; set; }
    }
}
```

- [ ] **Step 2: Update Datafono entity config in SQLSanContext.cs**

Find the `modelBuilder.Entity<Datafono>` block (lines 649-660) and replace with:

```csharp
            modelBuilder.Entity<Datafono>(entity =>
            {
                entity.HasKey(e => e.Iddatafono);

                entity.Property(e => e.Iddatafono).HasColumnName("iddatafono");

                entity.Property(e => e.Idbanco).HasColumnName("idbanco");

                entity.Property(e => e.Nombre)
                    .HasMaxLength(255)
                    .HasColumnName("nombre");

                entity.Property(e => e.Ip)
                    .HasMaxLength(45)
                    .HasColumnName("Ip");

                entity.Property(e => e.Puerto)
                    .HasDefaultValue(8080)
                    .HasColumnName("Puerto");
            });
```

- [ ] **Step 3: Verify build compiles**

```bash
cd "/media/juank/ADATA HD710 PRO/FuelRedMobil/FuelRedMobil"
dotnet build
```

Expected: Build succeeded

---

## Task 3: Backend - TransaccionPax Model + DbSet

**Files:**
- Create: `/media/juank/ADATA HD710 PRO/FuelRedMobil/FuelRedMobil/Models/TransaccionPax.cs`
- Modify: `/media/juank/ADATA HD710 PRO/FuelRedMobil/FuelRedMobil/Models/SQLSanContext.cs`

- [ ] **Step 1: Create TransaccionPax.cs**

```csharp
using System;

#nullable disable

namespace FuelRedMobil.Models
{
    public partial class TransaccionPax
    {
        public long Id { get; set; }
        public long? IdFactura { get; set; }
        public int? IdCierre { get; set; }
        public short? IdDatafono { get; set; }
        public string RespCode { get; set; }
        public string Autorizacion { get; set; }
        public string Stan { get; set; }
        public string PanMasked { get; set; }
        public string Rrn { get; set; }
        public string Recibo { get; set; }
        public string TerminalId { get; set; }
        public string MerchantId { get; set; }
        public string CardHolder { get; set; }
        public string IssuerName { get; set; }
        public string PosEntryMode { get; set; }
        public string CardHash { get; set; }
        public decimal? TotalAmount { get; set; }
        public decimal? BaseAmount { get; set; }
        public decimal? TipAmount { get; set; }
        public decimal? TaxAmount { get; set; }
        public string Ticket { get; set; }
        public string TxnId { get; set; }
        public string FechaPax { get; set; }
        public string Aid { get; set; }
        public string AppLabel { get; set; }
        public string Arqc { get; set; }
        public string Tvr { get; set; }
        public DateTime FechaRegistro { get; set; }
    }
}
```

- [ ] **Step 2: Add DbSet to SQLSanContext.cs**

After line 71 (`DbSet<Datafono> Datafonos`), add:

```csharp
        public virtual DbSet<TransaccionPax> TransaccionesPax { get; set; }
```

- [ ] **Step 3: Add entity config in SQLSanContext.cs OnModelCreating**

After the Datafono entity block (after the closing `});` around line 660), add:

```csharp
            modelBuilder.Entity<TransaccionPax>(entity =>
            {
                entity.HasKey(e => e.Id);

                entity.ToTable("TransaccionPax");

                entity.Property(e => e.Id)
                    .HasColumnName("Id")
                    .UseIdentityColumn();

                entity.Property(e => e.IdFactura).HasColumnName("IdFactura");
                entity.Property(e => e.IdCierre).HasColumnName("IdCierre");
                entity.Property(e => e.IdDatafono).HasColumnName("IdDatafono");
                entity.Property(e => e.RespCode).HasMaxLength(10).HasColumnName("RespCode");
                entity.Property(e => e.Autorizacion).HasMaxLength(50).HasColumnName("Autorizacion");
                entity.Property(e => e.Stan).HasMaxLength(20).HasColumnName("Stan");
                entity.Property(e => e.PanMasked).HasMaxLength(30).HasColumnName("PanMasked");
                entity.Property(e => e.Rrn).HasMaxLength(30).HasColumnName("Rrn");
                entity.Property(e => e.Recibo).HasMaxLength(20).HasColumnName("Recibo");
                entity.Property(e => e.TerminalId).HasMaxLength(20).HasColumnName("TerminalId");
                entity.Property(e => e.MerchantId).HasMaxLength(20).HasColumnName("MerchantId");
                entity.Property(e => e.CardHolder).HasMaxLength(100).HasColumnName("CardHolder");
                entity.Property(e => e.IssuerName).HasMaxLength(50).HasColumnName("IssuerName");
                entity.Property(e => e.PosEntryMode).HasMaxLength(10).HasColumnName("PosEntryMode");
                entity.Property(e => e.CardHash).HasMaxLength(200).HasColumnName("CardHash");
                entity.Property(e => e.TotalAmount).HasColumnType("decimal(18,2)").HasColumnName("TotalAmount");
                entity.Property(e => e.BaseAmount).HasColumnType("decimal(18,2)").HasColumnName("BaseAmount");
                entity.Property(e => e.TipAmount).HasColumnType("decimal(18,2)").HasColumnName("TipAmount");
                entity.Property(e => e.TaxAmount).HasColumnType("decimal(18,2)").HasColumnName("TaxAmount");
                entity.Property(e => e.Ticket).HasColumnName("Ticket");
                entity.Property(e => e.TxnId).HasMaxLength(50).HasColumnName("TxnId");
                entity.Property(e => e.FechaPax).HasMaxLength(30).HasColumnName("FechaPax");
                entity.Property(e => e.Aid).HasMaxLength(50).HasColumnName("Aid");
                entity.Property(e => e.AppLabel).HasMaxLength(50).HasColumnName("AppLabel");
                entity.Property(e => e.Arqc).HasMaxLength(50).HasColumnName("Arqc");
                entity.Property(e => e.Tvr).HasMaxLength(20).HasColumnName("Tvr");
                entity.Property(e => e.FechaRegistro)
                    .HasColumnName("FechaRegistro")
                    .HasDefaultValueSql("GETDATE()");

                entity.HasOne<Datafono>()
                    .WithMany()
                    .HasForeignKey(e => e.IdDatafono)
                    .OnDelete(DeleteBehavior.SetNull);

                entity.HasIndex(e => e.IdFactura);
                entity.HasIndex(e => e.IdCierre);
            });
```

- [ ] **Step 4: Verify build compiles**

```bash
cd "/media/juank/ADATA HD710 PRO/FuelRedMobil/FuelRedMobil"
dotnet build
```

Expected: Build succeeded

---

## Task 4: Backend - TransaccionesPaxController

**Files:**
- Create: `/media/juank/ADATA HD710 PRO/FuelRedMobil/FuelRedMobil/Controllers/API/TransaccionesPaxController.cs`

- [ ] **Step 1: Create the controller**

```csharp
using FuelRedMobil.Models;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

namespace FuelRedMobil.Controllers.API
{
    [Route("api/[controller]")]
    [ApiController]
    public class TransaccionesPaxController : ControllerBase
    {
        private readonly SQLSanContext _context;

        public TransaccionesPaxController(SQLSanContext context)
        {
            _context = context;
        }

        // GET: api/transaccionespax/factura/5
        [HttpGet("factura/{idFactura:long}")]
        public async Task<ActionResult<IEnumerable<TransaccionPax>>> GetByFactura(long idFactura, CancellationToken ct)
        {
            var data = await _context.TransaccionesPax
                .AsNoTracking()
                .Where(t => t.IdFactura == idFactura)
                .OrderByDescending(t => t.FechaRegistro)
                .ToListAsync(ct);

            return Ok(data);
        }

        // GET: api/transaccionespax/cierre/5
        [HttpGet("cierre/{idCierre:int}")]
        public async Task<ActionResult<IEnumerable<TransaccionPax>>> GetByCierre(int idCierre, CancellationToken ct)
        {
            var data = await _context.TransaccionesPax
                .AsNoTracking()
                .Where(t => t.IdCierre == idCierre)
                .OrderByDescending(t => t.FechaRegistro)
                .ToListAsync(ct);

            return Ok(data);
        }

        // POST: api/transaccionespax
        [HttpPost]
        public async Task<ActionResult<TransaccionPax>> PostTransaccionPax(TransaccionPax transaccion)
        {
            transaccion.FechaRegistro = DateTime.Now;
            _context.TransaccionesPax.Add(transaccion);

            try
            {
                await _context.SaveChangesAsync();
                return Ok(transaccion);
            }
            catch (DbUpdateException ex)
            {
                return Problem(
                    title: "Error guardando transaccion PAX",
                    detail: ex.Message,
                    statusCode: StatusCodes.Status500InternalServerError);
            }
        }
    }
}
```

- [ ] **Step 2: Verify build compiles**

```bash
cd "/media/juank/ADATA HD710 PRO/FuelRedMobil/FuelRedMobil"
dotnet build
```

Expected: Build succeeded

---

## Task 5: Flutter - PaxResponse Model

**Files:**
- Create: `/media/juank/Datos/flutter/tester/lib/Models/Pax/pax_response.dart`

- [ ] **Step 1: Create the PAX response model with error code mapping**

```dart
/// Represents the JSON response from the PAX A920 Web Service.
/// Used for venta, anulacion, and cierre operations.
class PaxResponse {
  final String respCode;
  final String autorizacion;
  final String stan;
  final String panMasked;
  final String rrn;
  final String recibo;
  final String terminalId;
  final String merchantId;
  final String cardHolder;
  final String issuerName;
  final String posEntryMode;
  final String cardHash;
  final String totalAmount;
  final String baseAmount;
  final String tipAmount;
  final String taxAmount;
  final String ticket;
  final String txnId;
  final String date;
  final String aid;
  final String appLabel;
  final String arqc;
  final String tvr;

  PaxResponse({
    this.respCode = '',
    this.autorizacion = '',
    this.stan = '',
    this.panMasked = '',
    this.rrn = '',
    this.recibo = '',
    this.terminalId = '',
    this.merchantId = '',
    this.cardHolder = '',
    this.issuerName = '',
    this.posEntryMode = '',
    this.cardHash = '',
    this.totalAmount = '',
    this.baseAmount = '',
    this.tipAmount = '',
    this.taxAmount = '',
    this.ticket = '',
    this.txnId = '',
    this.date = '',
    this.aid = '',
    this.appLabel = '',
    this.arqc = '',
    this.tvr = '',
  });

  bool get isApproved => respCode == '00';

  String get errorMessage => _respCodeMessages[respCode] ?? 'Error desconocido ($respCode)';

  factory PaxResponse.fromJson(Map<String, dynamic> json) {
    return PaxResponse(
      respCode: json['RESPCODE']?.toString() ?? '',
      autorizacion: json['AUTORIZACION']?.toString() ?? '',
      stan: json['STAN']?.toString() ?? '',
      panMasked: json['PANMASKED']?.toString() ?? '',
      rrn: json['RRN']?.toString() ?? '',
      recibo: json['RECIBO']?.toString() ?? '',
      terminalId: json['TERMINALID']?.toString() ?? '',
      merchantId: json['MERCHANTID']?.toString() ?? '',
      cardHolder: json['CARDHOLDER']?.toString() ?? '',
      issuerName: json['ISSUERNAME']?.toString() ?? '',
      posEntryMode: json['POSENTRYMODE']?.toString() ?? '',
      cardHash: json['CARDHASH']?.toString() ?? '',
      totalAmount: json['TOTAL_AMOUNT']?.toString() ?? '',
      baseAmount: json['BASE_AMOUNT']?.toString() ?? '',
      tipAmount: json['TIP_AMOUNT']?.toString() ?? '',
      taxAmount: json['TAX_AMOUNT']?.toString() ?? '',
      ticket: json['TICKET']?.toString() ?? '',
      txnId: json['TxnId']?.toString() ?? '',
      date: json['DATE']?.toString() ?? '',
      aid: json['AID']?.toString() ?? '',
      appLabel: json['APP_LABEL']?.toString() ?? '',
      arqc: json['ARQC']?.toString() ?? '',
      tvr: json['TVR']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'RESPCODE': respCode,
      'AUTORIZACION': autorizacion,
      'STAN': stan,
      'PANMASKED': panMasked,
      'RRN': rrn,
      'RECIBO': recibo,
      'TERMINALID': terminalId,
      'MERCHANTID': merchantId,
      'CARDHOLDER': cardHolder,
      'ISSUERNAME': issuerName,
      'POSENTRYMODE': posEntryMode,
      'CARDHASH': cardHash,
      'TOTAL_AMOUNT': totalAmount,
      'BASE_AMOUNT': baseAmount,
      'TIP_AMOUNT': tipAmount,
      'TAX_AMOUNT': taxAmount,
      'TICKET': ticket,
      'TxnId': txnId,
      'DATE': date,
      'AID': aid,
      'APP_LABEL': appLabel,
      'ARQC': arqc,
      'TVR': tvr,
    };
  }

  static const Map<String, String> _respCodeMessages = {
    '00': 'APROBADA',
    '01': 'CONSULTE VERBAL',
    '02': 'CONSULTE VERBAL',
    '03': 'COMERCIO INVALIDO',
    '04': 'CAPTURE TARJETA',
    '05': 'DENEGADA',
    '09': 'ACEPTADO',
    '12': 'TRANSACCION INVALIDA',
    '13': 'CANTIDAD INVALIDA',
    '14': 'TARJETA INVALIDA',
    '19': 'REINTENTE TRANSACCION',
    '21': 'SIN TRANSACCIONES',
    '25': 'REINTENTE',
    '41': 'RETENER TARJETA',
    '43': 'RETENER TARJETA',
    '51': 'DENEGADA FI',
    '54': 'TARJETA VENCIDA',
    '57': 'TRANSACCION NO PERMITIDA',
    '58': 'TRANSACCION NO PERMITIDA',
    '60': 'DENEGADA',
    '61': 'DENEGADA',
    '62': 'DENEGADA',
    '63': 'DENEGADA',
    '75': 'DENEGADA',
    '78': 'TRANSACCION NO ENCONTRADA',
    '79': 'LOTE YA ABIERTO',
    '80': 'ERROR EN NUMERO DE LOTE',
    '85': 'LOTE NO EXISTE',
    '89': 'TERMINAL INVALIDO',
    '94': 'TRANSACCION DUPLICADA',
    '95': 'ESPERE TRANSMISION',
    '96': 'ERROR EN SISTEMA',
    'NA': 'SISTEMA NO DISPONIBLE',
    'CE': 'ERROR DE COMUNICACION',
    'N7': 'CODIGO DE SEGURIDAD INVALIDO',
    'WE': 'ERROR INTERNO DEL WEB SERVICE',
    'X1': 'FONDOS INSUFICIENTES',
    'X4': 'NO ACEPTA ANULACION',
  };
}
```

- [ ] **Step 2: Commit**

```bash
cd /media/juank/Datos/flutter/tester
git add lib/Models/Pax/pax_response.dart
git commit -m "feat(pax): add PaxResponse model with error code mapping"
```

---

## Task 6: Flutter - TransaccionPax Model

**Files:**
- Create: `/media/juank/Datos/flutter/tester/lib/Models/Pax/transaccion_pax.dart`

- [ ] **Step 1: Create the backend-persisted model**

```dart
import 'package:tester/Models/Pax/pax_response.dart';

/// Mirrors the TransaccionPax table in SQLSan.
/// Used to persist PAX responses to the backend.
class TransaccionPax {
  int? id;
  int? idFactura;
  int? idCierre;
  int? idDatafono;
  String? respCode;
  String? autorizacion;
  String? stan;
  String? panMasked;
  String? rrn;
  String? recibo;
  String? terminalId;
  String? merchantId;
  String? cardHolder;
  String? issuerName;
  String? posEntryMode;
  String? cardHash;
  double? totalAmount;
  double? baseAmount;
  double? tipAmount;
  double? taxAmount;
  String? ticket;
  String? txnId;
  String? fechaPax;
  String? aid;
  String? appLabel;
  String? arqc;
  String? tvr;
  DateTime? fechaRegistro;

  TransaccionPax({
    this.id,
    this.idFactura,
    this.idCierre,
    this.idDatafono,
    this.respCode,
    this.autorizacion,
    this.stan,
    this.panMasked,
    this.rrn,
    this.recibo,
    this.terminalId,
    this.merchantId,
    this.cardHolder,
    this.issuerName,
    this.posEntryMode,
    this.cardHash,
    this.totalAmount,
    this.baseAmount,
    this.tipAmount,
    this.taxAmount,
    this.ticket,
    this.txnId,
    this.fechaPax,
    this.aid,
    this.appLabel,
    this.arqc,
    this.tvr,
    this.fechaRegistro,
  });

  /// Create from a PaxResponse after a successful PAX call.
  factory TransaccionPax.fromPaxResponse(
    PaxResponse response, {
    int? idFactura,
    int? idCierre,
    int? idDatafono,
  }) {
    return TransaccionPax(
      idFactura: idFactura,
      idCierre: idCierre,
      idDatafono: idDatafono,
      respCode: response.respCode,
      autorizacion: response.autorizacion,
      stan: response.stan,
      panMasked: response.panMasked,
      rrn: response.rrn,
      recibo: response.recibo,
      terminalId: response.terminalId,
      merchantId: response.merchantId,
      cardHolder: response.cardHolder,
      issuerName: response.issuerName,
      posEntryMode: response.posEntryMode,
      cardHash: response.cardHash,
      totalAmount: _parseAmount(response.totalAmount),
      baseAmount: _parseAmount(response.baseAmount),
      tipAmount: _parseAmount(response.tipAmount),
      taxAmount: _parseAmount(response.taxAmount),
      ticket: response.ticket,
      txnId: response.txnId,
      fechaPax: response.date,
      aid: response.aid,
      appLabel: response.appLabel,
      arqc: response.arqc,
      tvr: response.tvr,
    );
  }

  factory TransaccionPax.fromJson(Map<String, dynamic> json) {
    return TransaccionPax(
      id: json['id'],
      idFactura: json['idFactura'],
      idCierre: json['idCierre'],
      idDatafono: json['idDatafono'],
      respCode: json['respCode'],
      autorizacion: json['autorizacion'],
      stan: json['stan'],
      panMasked: json['panMasked'],
      rrn: json['rrn'],
      recibo: json['recibo'],
      terminalId: json['terminalId'],
      merchantId: json['merchantId'],
      cardHolder: json['cardHolder'],
      issuerName: json['issuerName'],
      posEntryMode: json['posEntryMode'],
      cardHash: json['cardHash'],
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      baseAmount: (json['baseAmount'] as num?)?.toDouble(),
      tipAmount: (json['tipAmount'] as num?)?.toDouble(),
      taxAmount: (json['taxAmount'] as num?)?.toDouble(),
      ticket: json['ticket'],
      txnId: json['txnId'],
      fechaPax: json['fechaPax'],
      aid: json['aid'],
      appLabel: json['appLabel'],
      arqc: json['arqc'],
      tvr: json['tvr'],
      fechaRegistro: json['fechaRegistro'] != null
          ? DateTime.parse(json['fechaRegistro'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idFactura': idFactura,
      'idCierre': idCierre,
      'idDatafono': idDatafono,
      'respCode': respCode,
      'autorizacion': autorizacion,
      'stan': stan,
      'panMasked': panMasked,
      'rrn': rrn,
      'recibo': recibo,
      'terminalId': terminalId,
      'merchantId': merchantId,
      'cardHolder': cardHolder,
      'issuerName': issuerName,
      'posEntryMode': posEntryMode,
      'cardHash': cardHash,
      'totalAmount': totalAmount,
      'baseAmount': baseAmount,
      'tipAmount': tipAmount,
      'taxAmount': taxAmount,
      'ticket': ticket,
      'txnId': txnId,
      'fechaPax': fechaPax,
      'aid': aid,
      'appLabel': appLabel,
      'arqc': arqc,
      'tvr': tvr,
    };
  }

  /// Parse PAX amount strings like "CRC11.00" or "-CRC10.00" to double.
  static double? _parseAmount(String raw) {
    if (raw.isEmpty) return null;
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.\-]'), '');
    return double.tryParse(cleaned);
  }
}
```

- [ ] **Step 2: Commit**

```bash
cd /media/juank/Datos/flutter/tester
git add lib/Models/Pax/transaccion_pax.dart
git commit -m "feat(pax): add TransaccionPax model with fromPaxResponse factory"
```

---

## Task 7: Flutter - PaxService

**Files:**
- Create: `/media/juank/Datos/flutter/tester/lib/services/pax_service.dart`

- [ ] **Step 1: Create the PAX HTTP service**

```dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:tester/Models/Pax/pax_response.dart';

/// Communicates with the PAX A920 terminal via its HTTP Web Service.
/// The terminal runs a web server on port 8080 when the financial app is open.
class PaxService {
  static const int _defaultTimeout = 60000; // 60s - time for customer to swipe card
  static const int _tamanoLinea = 42;
  static const String _delimitador = '|';

  /// Send a sale command to the PAX terminal.
  /// [monto] must be in cents (no decimals): 10.00 = 1000
  static Future<PaxResponse> venta({
    required String ip,
    required int puerto,
    required int monto,
    int? propina,
    int? impuesto,
    int timeout = _defaultTimeout,
  }) async {
    final params = <String, dynamic>{
      'monto': monto,
      'tamanoLinea': _tamanoLinea,
      'delimitador': _delimitador,
      'timeout': timeout,
    };
    if (propina != null && propina > 0) params['propina'] = propina;
    if (impuesto != null && impuesto > 0) params['impuesto'] = impuesto;

    return _execute(ip: ip, puerto: puerto, path: '/venta', params: params, timeout: timeout);
  }

  /// Send a void command to the PAX terminal.
  /// [recibo] is the receipt number from the original sale.
  static Future<PaxResponse> anulacion({
    required String ip,
    required int puerto,
    required String recibo,
    int timeout = _defaultTimeout,
  }) async {
    final params = <String, dynamic>{
      'recibo': recibo,
      'tamanoLinea': _tamanoLinea,
      'delimitador': _delimitador,
    };

    return _execute(ip: ip, puerto: puerto, path: '/anulacion', params: params, timeout: timeout);
  }

  /// Send a batch close command to the PAX terminal.
  static Future<PaxResponse> cierre({
    required String ip,
    required int puerto,
    int timeout = _defaultTimeout,
  }) async {
    final params = <String, dynamic>{
      'tamanoLinea': _tamanoLinea,
      'delimitador': _delimitador,
    };

    return _execute(ip: ip, puerto: puerto, path: '/cierre', params: params, timeout: timeout);
  }

  static Future<PaxResponse> _execute({
    required String ip,
    required int puerto,
    required String path,
    required Map<String, dynamic> params,
    required int timeout,
  }) async {
    final dio = Dio(BaseOptions(
      baseUrl: 'http://$ip:$puerto',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: Duration(milliseconds: timeout + 5000),
    ));

    try {
      final response = await dio.get(path, queryParameters: params);

      if (response.data is Map<String, dynamic>) {
        return PaxResponse.fromJson(response.data);
      }

      return PaxResponse(respCode: 'WE');
    } on DioException catch (e) {
      debugPrint('PaxService error: ${e.type} - ${e.message}');

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError) {
        return PaxResponse(respCode: 'CONNECT TIMEOUT');
      }

      if (e.type == DioExceptionType.receiveTimeout) {
        return PaxResponse(respCode: 'NA');
      }

      return PaxResponse(respCode: 'CE');
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
cd /media/juank/Datos/flutter/tester
git add lib/services/pax_service.dart
git commit -m "feat(pax): add PaxService for terminal HTTP communication"
```

---

## Task 8: Flutter - Update Datafono Model

**Files:**
- Modify: `/media/juank/Datos/flutter/tester/lib/Models/FuelRed/datafono.dart`

- [ ] **Step 1: Add ip and puerto fields**

Replace the full file:

```dart
class Datafono {
  int? iddatafono;
  int? idbanco;
  String? nombre;
  String? ip;
  int? puerto;

  Datafono({this.iddatafono, this.idbanco, this.nombre, this.ip, this.puerto});

  Datafono.fromJson(Map<String, dynamic> json) {
    iddatafono = json['iddatafono'];
    idbanco = json['idbanco'];
    nombre = json['nombre'];
    ip = json['ip'];
    puerto = json['puerto'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['iddatafono'] = iddatafono;
    data['idbanco'] = idbanco;
    data['nombre'] = nombre;
    data['ip'] = ip;
    data['puerto'] = puerto;
    return data;
  }

  /// Whether this datafono has PAX terminal connectivity configured.
  bool get hasPax => ip != null && ip!.isNotEmpty;
}
```

- [ ] **Step 2: Commit**

```bash
cd /media/juank/Datos/flutter/tester
git add lib/Models/FuelRed/datafono.dart
git commit -m "feat(pax): add ip and puerto fields to Datafono model"
```

---

## Task 9: Flutter - API Helper Endpoints

**Files:**
- Modify: `/media/juank/Datos/flutter/tester/lib/helpers/api_helper.dart`

- [ ] **Step 1: Add TransaccionPax API methods**

After the `getDatafonos()` method (around line 530), add:

```dart
  // ══════════════════════════════════════════════════════════════
  // PAX Transactions
  // ══════════════════════════════════════════════════════════════

  static Future<Response> postTransaccionPax(
      Map<String, dynamic> request) async {
    final response =
        await _dio.post('/api/TransaccionesPax', data: request);

    if (response.statusCode! >= 400) {
      return Response(
          isSuccess: false, message: response.data?.toString() ?? '');
    }
    return Response(isSuccess: true, result: response.data);
  }

  static Future<Response> getTransaccionesPaxByFactura(int idFactura) async {
    final response =
        await _dio.get('/api/TransaccionesPax/factura/$idFactura');

    if (response.statusCode! >= 400) {
      return Response(
          isSuccess: false, message: response.data?.toString() ?? '');
    }

    List<TransaccionPax> transacciones = [];
    if (response.data != null) {
      for (var item in response.data) {
        transacciones.add(TransaccionPax.fromJson(item));
      }
    }
    return Response(isSuccess: true, result: transacciones);
  }

  static Future<Response> getTransaccionesPaxByCierre(int idCierre) async {
    final response =
        await _dio.get('/api/TransaccionesPax/cierre/$idCierre');

    if (response.statusCode! >= 400) {
      return Response(
          isSuccess: false, message: response.data?.toString() ?? '');
    }

    List<TransaccionPax> transacciones = [];
    if (response.data != null) {
      for (var item in response.data) {
        transacciones.add(TransaccionPax.fromJson(item));
      }
    }
    return Response(isSuccess: true, result: transacciones);
  }
```

- [ ] **Step 2: Add the import at the top of api_helper.dart**

```dart
import 'package:tester/Models/Pax/transaccion_pax.dart';
```

- [ ] **Step 3: Commit**

```bash
cd /media/juank/Datos/flutter/tester
git add lib/helpers/api_helper.dart
git commit -m "feat(pax): add TransaccionPax API endpoints to ApiHelper"
```

---

## Task 10: Flutter - Integrate PAX into Checkout (goFact)

**Files:**
- Modify: `/media/juank/Datos/flutter/tester/lib/Screens/checkout/checkount.dart:777-886`

This is the core integration. We intercept `goFact()` to call the PAX terminal before saving the invoice.

- [ ] **Step 1: Add imports at top of checkount.dart**

```dart
import 'package:tester/services/pax_service.dart';
import 'package:tester/Models/Pax/pax_response.dart';
import 'package:tester/Models/Pax/transaccion_pax.dart';
import 'package:tester/Models/FuelRed/datafono.dart';
```

- [ ] **Step 2: Add helper method to find the card payment datafono**

Add this method in the `_CheckountScreenState` class (before `goFact`):

```dart
  /// Returns the card amount and associated datafono if the invoice has a card payment.
  /// Checks BAC, BN, Scotia, DAV in order - returns the first one with amount > 0.
  /// Returns null if no card payment.
  Future<(double amount, Datafono datafono)?> _findCardPayment(Invoice factura) async {
    final paid = factura.formPago!;

    // Map of payment method field -> amount
    final cardPayments = <String, double>{
      'bac': paid.totalBac,
      'bn': paid.totalBn,
      'scotia': paid.totalSctia,
      'dav': paid.totalDav,
    };

    // Find first card method with amount > 0
    final activeCard = cardPayments.entries.firstWhereOrNull((e) => e.value > 0);
    if (activeCard == null) return null;

    // Fetch datafonos from backend to get the one with PAX IP
    final response = await ApiHelper.getDatafonos();
    if (!response.isSuccess) return null;

    final List<Datafono> datafonos = response.result;

    // Find a datafono that has PAX configured (has IP)
    final datafono = datafonos.firstWhereOrNull((d) => d.hasPax);
    if (datafono == null) return null;

    return (activeCard.value, datafono);
  }
```

- [ ] **Step 3: Add the PAX overlay dialog method**

```dart
  /// Shows a modal overlay while waiting for the PAX terminal response.
  /// Returns the PaxResponse or null if cancelled.
  Future<PaxResponse?> _executePaxSale(Datafono datafono, int montoCentavos) async {
    PaxResponse? paxResult;
    bool cancelled = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        // Fire the PAX call
        PaxService.venta(
          ip: datafono.ip!,
          puerto: datafono.puerto ?? 8080,
          monto: montoCentavos,
        ).then((response) {
          paxResult = response;
          if (!cancelled && Navigator.of(dialogCtx).canPop()) {
            Navigator.of(dialogCtx).pop();
          }
        });

        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: kNewsurface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                const CircularProgressIndicator(color: kNewgreen),
                const SizedBox(height: 24),
                const Text(
                  'Procesando pago...',
                  style: TextStyle(
                    color: kNewtextPri,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pase la tarjeta en el terminal ${datafono.nombre}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: kNewtextMut, fontSize: 14),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    cancelled = true;
                    Navigator.of(dialogCtx).pop();
                  },
                  child: const Text('Cancelar', style: TextStyle(color: kNewred)),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (cancelled) return null;
    return paxResult;
  }
```

- [ ] **Step 4: Modify goFact() to intercept card payments**

Replace the `goFact` method (lines 777-886) with:

```dart
  Future<void> goFact(Invoice facturaApp) async {
    if (facturaApp.saldo != 0) {
      Fluttertoast.showToast(
        msg: "La factura aun tiene saldo.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: const Color.fromARGB(255, 70, 19, 15),
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }

    // ═══════════════════════════════════════════════════════════════
    // PAX INTEGRATION: If card payment exists, call PAX first
    // ═══════════════════════════════════════════════════════════════
    PaxResponse? paxResponse;
    Datafono? paxDatafono;
    double cardAmount = 0;

    final cardPayment = await _findCardPayment(facturaApp);
    if (cardPayment != null) {
      cardAmount = cardPayment.$1;
      paxDatafono = cardPayment.$2;

      // Convert to centavos (no decimals): 10.00 -> 1000
      final montoCentavos = (cardAmount * 100).round();

      paxResponse = await _executePaxSale(paxDatafono, montoCentavos);

      // User cancelled the dialog
      if (paxResponse == null) return;

      // PAX declined
      if (!paxResponse!.isApproved) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: kNewsurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Pago Denegado', style: TextStyle(color: kNewred)),
              content: Text(
                paxResponse!.errorMessage,
                style: const TextStyle(color: kNewtextPri),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Aceptar', style: TextStyle(color: kNewtextSec)),
                ),
              ],
            ),
          );
        }
        return;
      }
    }

    // ═══════════════════════════════════════════════════════════════
    // SAVE INVOICE (original flow)
    // ═══════════════════════════════════════════════════════════════
    setState(() {
      _showLoader = true;
    });

    final request = {
      'products': facturaApp.detail!.map((e) => e.toApiProducJson()).toList(),
      'idCierre': facturaApp.cierre!.idcierre,
      'cedualaUsuario': facturaApp.empleado!.cedulaEmpleado.toString(),
      'clienteFactura': facturaApp.formPago!.clienteFactura.toJson(),
      'totalEfectivo': facturaApp.formPago!.totalEfectivo,
      'totalBac': facturaApp.formPago!.totalBac,
      'totalDav': facturaApp.formPago!.totalDav,
      'totalBn': facturaApp.formPago!.totalBn,
      'totalSctia': facturaApp.formPago!.totalSctia,
      'totalSinpe': facturaApp.formPago!.totalSinpe,
      'totalDollars': facturaApp.formPago!.totalDollars,
      'totalCheques': facturaApp.formPago!.totalCheques,
      'totalCupones': facturaApp.formPago!.totalCupones,
      'totalPuntos': facturaApp.formPago!.totalPuntos,
      'totalTransfer': facturaApp.formPago!.totalTransfer,
      'saldo': facturaApp.saldo,
      'clientePuntos': facturaApp.formPago!.clientePuntos.toJson(),
      'Transferencia': facturaApp.formPago!.transfer.toJson(),
      'kms': kms.text.isEmpty ? '0' : kms.text,
      'placa': placa.text.isEmpty ? '' : placa.text,
      'sinpe': facturaApp.formPago!.sinpe.toJson(),
      'observaciones': obser.text.isEmpty ? '' : obser.text,
      'isticket': false,
      'isCredit': false,
      'plazo': 0,
      'isContado': true,
    };

    final Response response =
        await ApiHelper.post("Api/Facturacion/FacturaSp", request);

    // ═══════════════════════════════════════════════════════════════
    // PAX: Save transaction to backend if we had a PAX sale
    // ═══════════════════════════════════════════════════════════════
    if (paxResponse != null && paxResponse!.isApproved && response.isSuccess) {
      final decodedJson = jsonDecode(response.result);
      final tx = TransaccionPax.fromPaxResponse(
        paxResponse!,
        idFactura: decodedJson['idfactura'],
        idCierre: facturaApp.cierre!.idcierre,
        idDatafono: paxDatafono!.iddatafono,
      );
      await ApiHelper.postTransaccionPax(tx.toJson());
    }

    setState(() {
      _showLoader = false;
    });

    if (!response.isSuccess) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text(response.message),
              actions: <Widget>[
                TextButton(
                  child: const Text('Aceptar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
      return;
    }

    final decodedJson = jsonDecode(response.result);
    final Factura resdocFactura = Factura.fromJson(decodedJson);
    resdocFactura.usuario = facturaApp.empleado?.nombreCompleto;

    if (facturaApp.acumulaPuntos) {
      await _handleAcumulaPuntosPrint(
        facturaApp,
        facturaApp.empleado?.nombreCompleto ?? '',
      );
    }

    if (facturaApp.tieneTransferencia) {
      await _handleTransferenciaPrint(facturaApp);
    }

    if (facturaApp.canjeaPuntos) {
      await _handleCanjeaPuntosPrint(facturaApp);
    }

    if (facturaApp.tieneSinpe) {
      await _handleSinpePrint(facturaApp);
    }

    if (!mounted) return;

    final bool shouldPrint = await _confirmPrintFactura();
    if (shouldPrint) {
      await _handleFacturaPrint(resdocFactura);
    }

    await _goHomeSuccess(facturaApp);
  }
```

- [ ] **Step 5: Add the `firstWhereOrNull` import if not already present**

Check if `collection` package is available. If not, add this extension at the bottom of `checkount.dart`:

```dart
extension _IterableExt<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
```

- [ ] **Step 6: Commit**

```bash
cd /media/juank/Datos/flutter/tester
git add lib/Screens/checkout/checkount.dart
git commit -m "feat(pax): integrate PAX sale into invoice save flow"
```

---

## Task 11: Flutter - PAX Batch Close in Cierre Datafonos

**Files:**
- Modify: `/media/juank/Datos/flutter/tester/lib/Screens/CierreDatafonos/cierre_datafonos_screen.dart`

- [ ] **Step 1: Add imports**

```dart
import 'package:tester/services/pax_service.dart';
import 'package:tester/Models/Pax/pax_response.dart';
import 'package:tester/Models/Pax/transaccion_pax.dart';
import 'package:tester/Models/FuelRed/datafono.dart';
```

- [ ] **Step 2: Add PAX close method to the state class**

Add after the `onPrintPressed` method (after line 594):

```dart
  Future<void> _executePaxCierre() async {
    // Fetch datafonos to find ones with PAX IP
    final Response dfResponse = await ApiHelper.getDatafonos();
    if (!dfResponse.isSuccess || !mounted) return;

    final List<Datafono> datafonos = dfResponse.result;
    final paxDatafonos = datafonos.where((d) => d.hasPax).toList();

    if (paxDatafonos.isEmpty) {
      Fluttertoast.showToast(
        msg: 'No hay datafonos PAX configurados',
        backgroundColor: Colors.orange,
      );
      return;
    }

    // If multiple PAX, let user pick. If only one, use it directly.
    Datafono selected;
    if (paxDatafonos.length == 1) {
      selected = paxDatafonos.first;
    } else {
      final picked = await showModalBottomSheet<Datafono>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          decoration: const BoxDecoration(
            color: kNewsurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Selecciona terminal PAX',
                    style: TextStyle(color: kNewtextPri, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ...paxDatafonos.map((d) => ListTile(
                  title: Text(d.nombre ?? '', style: const TextStyle(color: kNewtextPri)),
                  subtitle: Text(d.ip ?? '', style: const TextStyle(color: kNewtextMut)),
                  onTap: () => Navigator.of(ctx).pop(d),
                )),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      );
      if (picked == null) return;
      selected = picked;
    }

    // Show progress and execute
    setState(() { showLoader = true; });

    final paxResponse = await PaxService.cierre(
      ip: selected.ip!,
      puerto: selected.puerto ?? 8080,
    );

    if (!mounted) return;
    setState(() { showLoader = false; });

    if (paxResponse.isApproved) {
      // Save PAX transaction
      final cierreActPro = Provider.of<CierreActivoProvider>(context, listen: false);
      final tx = TransaccionPax.fromPaxResponse(
        paxResponse,
        idCierre: cierreActPro.cierreFinal!.idcierre,
        idDatafono: selected.iddatafono,
      );
      await ApiHelper.postTransaccionPax(tx.toJson());

      Fluttertoast.showToast(
        msg: 'Cierre PAX completado',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      // Refresh the list
      _getCierres();
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: kNewsurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Error Cierre PAX', style: TextStyle(color: kNewred)),
          content: Text(paxResponse.errorMessage, style: const TextStyle(color: kNewtextPri)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    }
  }
```

- [ ] **Step 3: Add the PAX close button to the floating action area**

Replace the `floatingActionButton` in the `build` method (around line 132) with:

```dart
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.extended(
              heroTag: 'pax_cierre',
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              elevation: 0,
              onPressed: _executePaxCierre,
              icon: const Icon(Icons.contactless_outlined),
              label: const Text(
                'Cierre PAX',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            FloatingActionButton.extended(
              heroTag: 'add_cierre',
              backgroundColor: kNewgreen,
              foregroundColor: kNewtextPri,
              elevation: 0,
              onPressed: _goAdd,
              icon: const Icon(Icons.add),
              label: const Text(
                'Nuevo',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
```

- [ ] **Step 4: Commit**

```bash
cd /media/juank/Datos/flutter/tester
git add lib/Screens/CierreDatafonos/cierre_datafonos_screen.dart
git commit -m "feat(pax): add PAX batch close button to cierre datafonos screen"
```

---

## Task 12: Flutter - PAX Anulacion from Transaction History

**Files:**
- Modify: `/media/juank/Datos/flutter/tester/lib/Screens/checkout/checkount.dart`

This adds void/anulacion capability. Since anulación requires a `recibo` from a previous PAX transaction, we add a method that can be triggered from any screen that has a reference to a saved `TransaccionPax`.

- [ ] **Step 1: Add a static anulacion helper to PaxService usage in a reusable way**

Add to `/media/juank/Datos/flutter/tester/lib/services/pax_service.dart`, a convenience function at the bottom of the file:

```dart
import 'package:flutter/material.dart';
import 'package:tester/Models/Pax/transaccion_pax.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:tester/Models/FuelRed/response.dart' as app;

/// Executes a PAX void and saves the result to the backend.
/// Shows a progress dialog while waiting.
/// Returns true if the void was approved.
Future<bool> executePaxAnulacion({
  required BuildContext context,
  required String ip,
  required int puerto,
  required String recibo,
  int? idCierre,
  int? idDatafono,
}) async {
  // Show progress
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: Color(0xFF1A2332),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF22C55E)),
            SizedBox(height: 16),
            Text('Procesando anulacion...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    ),
  );

  final paxResponse = await PaxService.anulacion(
    ip: ip,
    puerto: puerto,
    recibo: recibo,
  );

  // Close progress dialog
  if (context.mounted && Navigator.of(context).canPop()) {
    Navigator.of(context).pop();
  }

  if (paxResponse.isApproved) {
    // Save void transaction
    final tx = TransaccionPax.fromPaxResponse(
      paxResponse,
      idCierre: idCierre,
      idDatafono: idDatafono,
    );
    await ApiHelper.postTransaccionPax(tx.toJson());
    return true;
  }

  // Show error
  if (context.mounted) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2332),
        title: const Text('Anulacion Denegada', style: TextStyle(color: Colors.red)),
        content: Text(paxResponse.errorMessage, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  return false;
}
```

- [ ] **Step 2: Commit**

```bash
cd /media/juank/Datos/flutter/tester
git add lib/services/pax_service.dart
git commit -m "feat(pax): add reusable PAX anulacion helper"
```

---

## Task 13: Verification - Build and Smoke Test

- [ ] **Step 1: Verify Flutter project compiles**

```bash
cd /media/juank/Datos/flutter/tester
flutter analyze lib/Models/Pax/ lib/services/pax_service.dart lib/Models/FuelRed/datafono.dart
```

Expected: No errors

- [ ] **Step 2: Verify .NET backend compiles**

```bash
cd "/media/juank/ADATA HD710 PRO/FuelRedMobil/FuelRedMobil"
dotnet build
```

Expected: Build succeeded

- [ ] **Step 3: Run the SQL migration against the Docker database**

User must run the `sql/pax_migration.sql` script against the SQLSan database in the Docker container. Verify:
- `SELECT * FROM Datafono` shows the new `Ip` and `Puerto` columns
- `SELECT * FROM TransaccionPax` returns empty (table exists)

- [ ] **Step 4: Configure a datafono with PAX IP**

```sql
UPDATE Datafono SET Ip = '192.168.88.19', Puerto = 8080 WHERE Iddatafono = <ID_OF_BAC_DATAFONO>;
```

- [ ] **Step 5: End-to-end test**

1. Open the app, create an invoice with products
2. Select BAC as payment method for the full balance
3. Tap "Facturar"
4. Verify the PAX overlay appears: "Procesando pago... Pase la tarjeta en el terminal"
5. Swipe a test card on the PAX A920
6. If RESPCODE=00: invoice saves and PAX transaction is persisted
7. Verify in DB: `SELECT * FROM TransaccionPax` has a new row

- [ ] **Step 6: Test cierre**

1. Go to Cierre Datafonos screen
2. Tap "Cierre PAX" button
3. Verify batch close executes on PAX
4. Verify response is saved in TransaccionPax table
