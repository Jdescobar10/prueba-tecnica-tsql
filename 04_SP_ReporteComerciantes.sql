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
-- Ajuste 1:
-- Autor  : Juan David Escobar
-- Fecha  : 2026-03-07
-- Descripción: Se cambian los alias o nombre de los campos para
--              que no tengan espacios ya que en la capa de WEB API
--              se presentoproblemas con EF.
-- Detalle del error:  error 0xffffffff — eso significa que crasheó 
--             completamente. El atributo [Column] de 
--             System.ComponentModel.DataAnnotations no funciona con 
--             FromSql de EF Core para mapear nombres con espacios.
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
    c.ComercianteId,
    c.NombreRazonSocial,
    m.Nombre              AS Municipio,
    c.Telefono,
    c.CorreoElectronico,
    c.FechaRegistro,
    e.Nombre              AS Estado,
    ISNULL(r.CantidadEstablecimientos, 0) AS CantidadEstablecimientos,
    ISNULL(r.TotalIngresos, 0)            AS TotalIngresos,
    ISNULL(r.CantidadEmpleados, 0)        AS CantidadEmpleados
	FROM Comerciante c
	INNER JOIN Municipio m  ON c.MunicipioId = m.MunicipioId
	INNER JOIN Estado e     ON c.EstadoId    = e.EstadoId
	LEFT JOIN dbo.fn_ObtenerResumenEstablecimientos() r 
							ON c.ComercianteId = r.ComercianteId
	WHERE e.Nombre = 'Activo'
	ORDER BY CantidadEstablecimientos DESC;

END;
GO

-- ──────────────────────────────────────────────────────────
-- EJECUCIÓN DE PRUEBA
-- ──────────────────────────────────────────────────────────
-- EXEC dbo.sp_ReporteComerciantes;

PRINT '>>> Script 04 ejecutado correctamente: SP de reporte creado.';
GO
