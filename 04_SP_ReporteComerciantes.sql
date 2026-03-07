-- ============================================================
-- Nombre: 04_SP_ReporteComerciantes.sql
-- SCRIPT 04 - STORED PROCEDURE: Reporte de Comerciantes
-- Autor  : Juan David Escobar
-- Fecha  : 2026-03-06
-- Descripción: Retorna los comerciantes ACTIVOS con:
--              - Datos del comerciante
--              - Cantidad de establecimientos asociados
--              - Total de ingresos (suma)
--              - Total de empleados (suma)
--              Ordenados de forma DESCENDENTE por cantidad
--              de establecimientos.
-- ============================================================

USE AgremiacionComercio;
GO

-- ──────────────────────────────────────────────────────────
-- FUNCIÓN AUXILIAR: fn_ObtenerResumenEstablecimientos
-- Propósito: Encapsula el cálculo de los agregados por
--            comerciante para reutilización y legibilidad.
-- ──────────────────────────────────────────────────────────
IF OBJECT_ID('dbo.fn_ObtenerResumenEstablecimientos', 'IF') IS NOT NULL
    DROP FUNCTION dbo.fn_ObtenerResumenEstablecimientos;
GO

CREATE FUNCTION dbo.fn_ObtenerResumenEstablecimientos()
RETURNS TABLE
AS
RETURN
(
    SELECT
        e.ComercianteId,
        COUNT(e.EstablecimientoId)  AS CantidadEstablecimientos,
        SUM(e.Ingresos)             AS TotalIngresos,
        SUM(e.NumeroEmpleados)      AS CantidadEmpleados
    FROM dbo.Establecimiento e
    GROUP BY e.ComercianteId
);
GO

-- ──────────────────────────────────────────────────────────
-- STORED PROCEDURE: sp_ReporteComerciantes
-- ──────────────────────────────────────────────────────────
IF OBJECT_ID('dbo.sp_ReporteComerciantes', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_ReporteComerciantes;
GO

CREATE PROCEDURE dbo.sp_ReporteComerciantes
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        c.NombreRazonSocial                         AS [Nombre / Razón Social],
        m.Nombre                                    AS [Municipio],
        ISNULL(c.Telefono,        'N/A')            AS [Teléfono],
        ISNULL(c.CorreoElectronico, 'N/A')          AS [Correo Electrónico],
        FORMAT(c.FechaRegistro, 'yyyy-MM-dd')       AS [Fecha de Registro],
        est.Nombre                                  AS [Estado],
        ISNULL(r.CantidadEstablecimientos,  0)      AS [Cantidad de Establecimientos],
        ISNULL(r.TotalIngresos,             0.00)   AS [Total Ingresos],
        ISNULL(r.CantidadEmpleados,         0)      AS [Cantidad de Empleados]
    FROM       dbo.Comerciante                          c
    INNER JOIN dbo.Estado                               est ON est.EstadoId    = c.EstadoId
    INNER JOIN dbo.Municipio                            m   ON m.MunicipioId   = c.MunicipioId
    -- LEFT JOIN para incluir comerciantes activos sin establecimientos
    LEFT  JOIN dbo.fn_ObtenerResumenEstablecimientos()  r   ON r.ComercianteId = c.ComercianteId
    WHERE
        est.Nombre = 'Activo'
    ORDER BY
        ISNULL(r.CantidadEstablecimientos, 0) DESC;
END;
GO

-- ──────────────────────────────────────────────────────────
-- EJECUCIÓN DE PRUEBA
-- ──────────────────────────────────────────────────────────
-- EXEC dbo.sp_ReporteComerciantes;

PRINT '>>> Script 04 ejecutado correctamente: SP de reporte creado.';
GO
