-- ============================================================
-- Nombre:  01_Crear_DatabaseTablesIndex.sql
-- SCRIPT 01: Creación de Base de Datos, Tablas e indices
-- Autor  : Juan David Escobar
-- Fecha  : 2026-03-06
-- Descripción: Crea la BD y el modelo de datos normalizado
--              para la Agremiación Nacional de Comercio.
-- ============================================================

-- ──────────────────────────────────────────────────────────
-- 1. BASE DE DATOS
-- ──────────────────────────────────────────────────────────
IF NOT EXISTS (
    SELECT name FROM sys.databases WHERE name = N'AgremiacionComercio'
)
BEGIN
    CREATE DATABASE AgremiacionComercio;
END
GO

USE AgremiacionComercio;
GO

-- ──────────────────────────────────────────────────────────
-- 2. TABLA: Rol
--    Normalización del campo Rol del Usuario.
-- ──────────────────────────────────────────────────────────
IF OBJECT_ID('dbo.Rol', 'U') IS NOT NULL
    DROP TABLE dbo.Rol;
GO

CREATE TABLE dbo.Rol (
    RolId       INT           NOT NULL IDENTITY(1,1),
    Nombre      NVARCHAR(50)  NOT NULL,   -- 'Administrador' | 'Auxiliar de Registro'

    CONSTRAINT PK_Rol PRIMARY KEY (RolId),
    CONSTRAINT UQ_Rol_Nombre UNIQUE (Nombre)
);
GO

-- ──────────────────────────────────────────────────────────
-- 3. TABLA: Usuario
-- ──────────────────────────────────────────────────────────
IF OBJECT_ID('dbo.Usuario', 'U') IS NOT NULL
    DROP TABLE dbo.Usuario;
GO

CREATE TABLE dbo.Usuario (
    UsuarioId       INT             NOT NULL IDENTITY(1,1),
    Nombre          NVARCHAR(150)   NOT NULL,
    CorreoElectronico NVARCHAR(255) NOT NULL,
    Contrasena      NVARCHAR(255)   NOT NULL,   -- Se recomienda almacenar hash en producción
    RolId           INT             NOT NULL,

    CONSTRAINT PK_Usuario       PRIMARY KEY (UsuarioId),
    CONSTRAINT UQ_Usuario_Correo UNIQUE (CorreoElectronico),
    CONSTRAINT FK_Usuario_Rol   FOREIGN KEY (RolId) REFERENCES dbo.Rol(RolId)
);
GO

-- ──────────────────────────────────────────────────────────
-- 4. TABLA: Municipio
--    Normalización del municipio del Comerciante.
-- ──────────────────────────────────────────────────────────
IF OBJECT_ID('dbo.Municipio', 'U') IS NOT NULL
    DROP TABLE dbo.Municipio;
GO

CREATE TABLE dbo.Municipio (
    MunicipioId INT           NOT NULL IDENTITY(1,1),
    Nombre      NVARCHAR(150) NOT NULL,

    CONSTRAINT PK_Municipio PRIMARY KEY (MunicipioId),
    CONSTRAINT UQ_Municipio_Nombre UNIQUE (Nombre)
);
GO

-- ──────────────────────────────────────────────────────────
-- 5. TABLA: Estado
--    Normalización del Estado del Comerciante.
-- ──────────────────────────────────────────────────────────
IF OBJECT_ID('dbo.Estado', 'U') IS NOT NULL
    DROP TABLE dbo.Estado;
GO

CREATE TABLE dbo.Estado (
    EstadoId    INT          NOT NULL IDENTITY(1,1),
    Nombre      NVARCHAR(50) NOT NULL,   -- 'Activo' | 'Inactivo'

    CONSTRAINT PK_Estado PRIMARY KEY (EstadoId),
    CONSTRAINT UQ_Estado_Nombre UNIQUE (Nombre)
);
GO

-- ──────────────────────────────────────────────────────────
-- 6. TABLA: Comerciante
--    Campos de auditoría: FechaActualizacion y UsuarioAuditoria
--    gestionados por trigger (ver Script 02).
-- ──────────────────────────────────────────────────────────
IF OBJECT_ID('dbo.Comerciante', 'U') IS NOT NULL
    DROP TABLE dbo.Comerciante;
GO

CREATE TABLE dbo.Comerciante (
    ComercianteId       INT             NOT NULL IDENTITY(1,1),
    NombreRazonSocial   NVARCHAR(255)   NOT NULL,
    MunicipioId         INT             NOT NULL,
    Telefono            NVARCHAR(20)    NULL,
    CorreoElectronico   NVARCHAR(255)   NULL,
    FechaRegistro       DATE            NOT NULL CONSTRAINT DF_Comerciante_FechaRegistro DEFAULT (CAST(GETDATE() AS DATE)),
    EstadoId            INT             NOT NULL,
    -- Campos de auditoría
    FechaActualizacion  DATETIME2(0)    NULL,
    UsuarioAuditoria    NVARCHAR(255)   NULL,

    CONSTRAINT PK_Comerciante           PRIMARY KEY (ComercianteId),
    CONSTRAINT FK_Comerciante_Municipio FOREIGN KEY (MunicipioId)  REFERENCES dbo.Municipio(MunicipioId),
    CONSTRAINT FK_Comerciante_Estado    FOREIGN KEY (EstadoId)     REFERENCES dbo.Estado(EstadoId)
);
GO

-- ──────────────────────────────────────────────────────────
-- 7. TABLA: Establecimiento
--    Campos de auditoría: FechaActualizacion y UsuarioAuditoria
--    gestionados por trigger (ver Script 02).
-- ──────────────────────────────────────────────────────────
IF OBJECT_ID('dbo.Establecimiento', 'U') IS NOT NULL
    DROP TABLE dbo.Establecimiento;
GO

CREATE TABLE dbo.Establecimiento (
    EstablecimientoId   INT             NOT NULL IDENTITY(1,1),
    Nombre              NVARCHAR(255)   NOT NULL,
    Ingresos            DECIMAL(18,2)   NOT NULL,
    NumeroEmpleados     INT             NOT NULL,
    ComercianteId       INT             NOT NULL,
    -- Campos de auditoría
    FechaActualizacion  DATETIME2(0)    NULL,
    UsuarioAuditoria    NVARCHAR(255)   NULL,

    CONSTRAINT PK_Establecimiento           PRIMARY KEY (EstablecimientoId),
    CONSTRAINT FK_Establecimiento_Comerciante FOREIGN KEY (ComercianteId) REFERENCES dbo.Comerciante(ComercianteId),
    CONSTRAINT CHK_Establecimiento_Ingresos   CHECK (Ingresos >= 0),
    CONSTRAINT CHK_Establecimiento_Empleados  CHECK (NumeroEmpleados >= 0)
);
GO

-- ──────────────────────────────────────────────────────────
-- 8. ÍNDICES
-- ──────────────────────────────────────────────────────────

-- Usuario: búsqueda frecuente por correo (login)
CREATE NONCLUSTERED INDEX IX_Usuario_CorreoElectronico
    ON dbo.Usuario (CorreoElectronico);
GO

-- Comerciante: filtro por estado (Activo/Inactivo) y municipio
CREATE NONCLUSTERED INDEX IX_Comerciante_EstadoId
    ON dbo.Comerciante (EstadoId)
    INCLUDE (NombreRazonSocial, MunicipioId, Telefono, CorreoElectronico, FechaRegistro);
GO

CREATE NONCLUSTERED INDEX IX_Comerciante_MunicipioId
    ON dbo.Comerciante (MunicipioId);
GO

-- Establecimiento: búsqueda por comerciante (JOIN frecuente en reporte)
CREATE NONCLUSTERED INDEX IX_Establecimiento_ComercianteId
    ON dbo.Establecimiento (ComercianteId)
    INCLUDE (Nombre, Ingresos, NumeroEmpleados);
GO

PRINT '>>> Script 01 ejecutado correctamente: BD y tablas creadas.';
GO
