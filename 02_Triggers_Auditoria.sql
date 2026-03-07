-- ============================================================
-- Nombre: 02_Triggers_Auditoria.sql
-- SCRIPT 02 - TRIGGERS: Auditoría automática
-- Autor  : Juan David Escobar
-- Fecha  : 2026-03-06
-- Descripción: Triggers AFTER INSERT, UPDATE sobre Comerciante
--              y Establecimiento para mantener FechaActualizacion
--              y UsuarioAuditoria actualizados automáticamente.
-- ============================================================

USE AgremiacionComercio;
GO

-- ──────────────────────────────────────────────────────────
-- TRIGGER: trg_Comerciante_Auditoria
-- Evento  : AFTER INSERT, UPDATE
-- Tabla   : dbo.Comerciante
-- ──────────────────────────────────────────────────────────
IF OBJECT_ID('dbo.trg_Comerciante_Auditoria', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_Comerciante_Auditoria;
GO

CREATE TRIGGER dbo.trg_Comerciante_Auditoria
ON dbo.Comerciante
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Evita recursión si el propio trigger dispara otra actualización
    IF TRIGGER_NESTLEVEL() > 1 RETURN;

    UPDATE c
    SET
        c.FechaActualizacion = GETDATE(),
        -- Captura el usuario de la sesión activa; ajustable según capa de aplicación
        c.UsuarioAuditoria   = SYSTEM_USER
    FROM dbo.Comerciante c
    INNER JOIN inserted i ON c.ComercianteId = i.ComercianteId;
END;
GO

-- ──────────────────────────────────────────────────────────
-- TRIGGER: trg_Establecimiento_Auditoria
-- Evento  : AFTER INSERT, UPDATE
-- Tabla   : dbo.Establecimiento
-- ──────────────────────────────────────────────────────────
IF OBJECT_ID('dbo.trg_Establecimiento_Auditoria', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_Establecimiento_Auditoria;
GO

CREATE TRIGGER dbo.trg_Establecimiento_Auditoria
ON dbo.Establecimiento
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF TRIGGER_NESTLEVEL() > 1 RETURN;

    UPDATE e
    SET
        e.FechaActualizacion = GETDATE(),
        e.UsuarioAuditoria   = SYSTEM_USER
    FROM dbo.Establecimiento e
    INNER JOIN inserted i ON e.EstablecimientoId = i.EstablecimientoId;
END;
GO

PRINT '>>> Script 02 ejecutado correctamente: Triggers de auditoría creados.';
GO
