-- ============================================================
-- Name:  03_Datos_Semilla.sql
-- SCRIPT 03: Datos Semilla
-- Autor  : Juan David Escobar
-- Fecha  : 2026-03-06
-- Descripción: Inserta los datos iniciales requeridos:
--              - Catálogos (Roles, Municipios, Estados)
--              - 2 Usuarios (uno por rol)
--              - 5 Comerciantes
--              - 10 Establecimientos (distribución aleatoria)
-- ============================================================

USE AgremiacionComercio;
GO

-- ──────────────────────────────────────────────────────────
-- 1. CATÁLOGOS BASE
-- ──────────────────────────────────────────────────────────

-- Roles
IF NOT EXISTS (SELECT 1 FROM dbo.Rol WHERE Nombre = 'Administrador')
    INSERT INTO dbo.Rol (Nombre) VALUES ('Administrador');

IF NOT EXISTS (SELECT 1 FROM dbo.Rol WHERE Nombre = 'Auxiliar de Registro')
    INSERT INTO dbo.Rol (Nombre) VALUES ('Auxiliar de Registro');
GO

-- Estados
IF NOT EXISTS (SELECT 1 FROM dbo.Estado WHERE Nombre = 'Activo')
    INSERT INTO dbo.Estado (Nombre) VALUES ('Activo');

IF NOT EXISTS (SELECT 1 FROM dbo.Estado WHERE Nombre = 'Inactivo')
    INSERT INTO dbo.Estado (Nombre) VALUES ('Inactivo');
GO

-- Municipios (ciudades colombianas representativas)
INSERT INTO dbo.Municipio (Nombre)
SELECT v.Nombre
FROM (VALUES
    ('Bogotá D.C.'),
    ('Medellín'),
    ('Cali'),
    ('Barranquilla'),
    ('Cartagena de Indias'),
    ('Bucaramanga'),
    ('Pereira'),
    ('Manizales')
) AS v(Nombre)
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.Municipio m WHERE m.Nombre = v.Nombre
);
GO

-- ──────────────────────────────────────────────────────────
-- 2. USUARIOS (2 registros, uno por rol)
-- ──────────────────────────────────────────────────────────
-- Nota: En un entorno real la contraseña se almacenaría
--       como hash (bcrypt / SHA-256). Aquí se guarda en
--       texto plano únicamente como dato semilla de prueba.

INSERT INTO dbo.Usuario (Nombre, CorreoElectronico, Contrasena, RolId)
SELECT v.Nombre, v.Correo, v.Contrasena, r.RolId
FROM (VALUES
    ('Carlos Mendoza',    'admin@agremiacion.com',    'Admin$2026!',   'Administrador'),
    ('Laura Jiménez',     'auxiliar@agremiacion.com', 'Aux1liar#2026', 'Auxiliar de Registro')
) AS v(Nombre, Correo, Contrasena, Rol)
INNER JOIN dbo.Rol r ON r.Nombre = v.Rol
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.Usuario u WHERE u.CorreoElectronico = v.Correo
);
GO

-- ──────────────────────────────────────────────────────────
-- 3. COMERCIANTES (5 registros)
-- ──────────────────────────────────────────────────────────
INSERT INTO dbo.Comerciante
    (NombreRazonSocial, MunicipioId, Telefono, CorreoElectronico, FechaRegistro, EstadoId)
SELECT
    v.NombreRazonSocial,
    m.MunicipioId,
    v.Telefono,
    v.Correo,
    v.FechaRegistro,
    e.EstadoId
FROM (VALUES
    ('Distribuidora Andina S.A.S.',   'Medellín',            '6044521890', 'contacto@distribuidoraandina.com', '2022-03-15', 'Activo'),
    ('Comercializadora del Norte',    'Barranquilla',         '6053318742', NULL,                               '2021-07-20', 'Activo'),
    ('Inversiones Pacífico Ltda.',    'Cali',                 NULL,         'info@inversionespacifico.co',      '2023-01-10', 'Activo'),
    ('Grupo Empresarial Café',        'Manizales',            '6068891234', 'gerencia@grupocafe.com',           '2020-11-05', 'Activo'),
    ('Ferretería Industrial Bogotá',  'Bogotá D.C.',          '6013357890', NULL,                               '2019-06-30', 'Inactivo')
) AS v(NombreRazonSocial, Municipio, Telefono, Correo, FechaRegistro, Estado)
INNER JOIN dbo.Municipio m ON m.Nombre = v.Municipio
INNER JOIN dbo.Estado    e ON e.Nombre = v.Estado
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.Comerciante c WHERE c.NombreRazonSocial = v.NombreRazonSocial
);
GO

-- ──────────────────────────────────────────────────────────
-- 4. ESTABLECIMIENTOS (10 registros, distribución aleatoria)
--    Distribución:
--      Comerciante 1 → 3 establecimientos
--      Comerciante 2 → 3 establecimientos
--      Comerciante 3 → 2 establecimientos
--      Comerciante 4 → 1 establecimiento
--      Comerciante 5 → 1 establecimiento
-- ──────────────────────────────────────────────────────────
DECLARE
    @C1 INT = (SELECT ComercianteId FROM dbo.Comerciante WHERE NombreRazonSocial = 'Distribuidora Andina S.A.S.'),
    @C2 INT = (SELECT ComercianteId FROM dbo.Comerciante WHERE NombreRazonSocial = 'Comercializadora del Norte'),
    @C3 INT = (SELECT ComercianteId FROM dbo.Comerciante WHERE NombreRazonSocial = 'Inversiones Pacífico Ltda.'),
    @C4 INT = (SELECT ComercianteId FROM dbo.Comerciante WHERE NombreRazonSocial = 'Grupo Empresarial Café'),
    @C5 INT = (SELECT ComercianteId FROM dbo.Comerciante WHERE NombreRazonSocial = 'Ferretería Industrial Bogotá');

INSERT INTO dbo.Establecimiento (Nombre, Ingresos, NumeroEmpleados, ComercianteId)
VALUES
    -- Distribuidora Andina S.A.S. (3)
    ('Sucursal Laureles',          85400000.50,  12, @C1),
    ('Sucursal El Poblado',       120750000.00,  20, @C1),
    ('Bodega Central Medellín',    67300000.75,   8, @C1),
    -- Comercializadora del Norte (3)
    ('Tienda Norte Centro',        45000000.00,   6, @C2),
    ('Punto de Venta Atlántico',   93200000.25,  15, @C2),
    ('Almacén Barranquilla Sur',   38500000.00,   5, @C2),
    -- Inversiones Pacífico (2)
    ('Oficina Cali Principal',    110000000.00,  18, @C3),
    ('Depósito Valle del Cauca',   52400000.50,   9, @C3),
    -- Grupo Empresarial Café (1)
    ('Local Manizales Centro',     29750000.00,   4, @C4),
    -- Ferretería Industrial Bogotá (1)
    ('Ferretería Zona Industrial', 74600000.00,  11, @C5);
GO

PRINT '>>> Script 03 ejecutado correctamente: Datos semilla insertados.';
GO
