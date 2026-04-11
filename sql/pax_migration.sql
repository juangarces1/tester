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
    RespCode VARCHAR(20) NULL,
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
