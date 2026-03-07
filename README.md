<div align="center">

# 🏛️ FULLSTACK T-SQL
## AgremiacionComercio

![SQL Server](https://img.shields.io/badge/SQL%20Server-T--SQL-CC2927?style=for-the-badge&logo=microsoftsqlserver&logoColor=white)
![Status](https://img.shields.io/badge/Estado-Producción-10b981?style=for-the-badge)
![Version](https://img.shields.io/badge/Versión-1.0.0-00d4ff?style=for-the-badge)
![Normalization](https://img.shields.io/badge/Normalización-3FN-7c3aed?style=for-the-badge)

> Base de datos relacional para la gestión de comerciantes y sus establecimientos, construida sobre **SQL Server** con **T-SQL**.  
> Incluye modelo ER completo, triggers de auditoría, datos semilla y stored procedure de reporte.

**Autor:** Juan David Escobar &nbsp;·&nbsp; **Fecha:** 2026-03-06

</div>

---

## 📋 Tabla de Contenido

- [Modelo Entidad-Relación](#-modelo-entidad-relación)
- [Estructura de Tablas](#-estructura-de-tablas)
- [Normalizaciones Aplicadas](#-normalizaciones-aplicadas-3fn)
- [Orden de Ejecución de Scripts](#-orden-de-ejecución-de-scripts)
- [Triggers de Auditoría](#-triggers-de-auditoría)
- [Stored Procedure — Reporte de Comerciantes](#-stored-procedure--reporte-de-comerciantes)
- [Nota de Seguridad](#️-nota-de-seguridad)

---

## 🗺️ Modelo Entidad-Relación

El diagrama completo puede visualizarse abriendo el archivo **`00_AgremiacionComercio.html`** en cualquier navegador moderno. A continuación se describe la estructura de relaciones:

```
  ┌─────────┐        ┌──────────────┐
  │   Rol   │ 1 ── N │   Usuario    │
  └─────────┘        └──────────────┘

  ┌─────────┐
  │  Estado │ 1 ─────────────┐
  └─────────┘                │
                             ▼
  ┌──────────┐        ┌──────────────┐        ┌──────────────────┐
  │ Municipio│ 1 ── N │  Comerciante │ 1 ── N │ Establecimiento  │
  └──────────┘        └──────────────┘        └──────────────────┘
```

### Relaciones

| Tabla Origen | Cardinalidad | Tabla Destino     | FK en destino   |
|:-------------|:------------:|:------------------|:----------------|
| `Rol`        | 1 : N        | `Usuario`         | `RolId`         |
| `Estado`     | 1 : N        | `Comerciante`     | `EstadoId`      |
| `Municipio`  | 1 : N        | `Comerciante`     | `MunicipioId`   |
| `Comerciante`| 1 : N        | `Establecimiento` | `ComercianteId` |

---

## 🗄️ Estructura de Tablas

### 🟣 `dbo.Rol`
| Campo | Tipo | Restricción |
|:------|:-----|:------------|
| `RolId` | `INT` | 🔑 PK · IDENTITY |
| `Nombre` | `NVARCHAR(50)` | NOT NULL |

---

### 🟣 `dbo.Usuario`
| Campo | Tipo | Restricción |
|:------|:-----|:------------|
| `UsuarioId` | `INT` | 🔑 PK · IDENTITY |
| `Nombre` | `NVARCHAR(150)` | NOT NULL |
| `CorreoElectronico` | `NVARCHAR(255)` | NOT NULL |
| `Contrasena` | `NVARCHAR(255)` | NOT NULL *(hash)* |
| `RolId` | `INT` | 🔗 FK → `Rol` |

---

### 🟢 `dbo.Estado`
| Campo | Tipo | Restricción |
|:------|:-----|:------------|
| `EstadoId` | `INT` | 🔑 PK · IDENTITY |
| `Nombre` | `NVARCHAR(50)` | NOT NULL |

---

### 🟡 `dbo.Municipio`
| Campo | Tipo | Restricción |
|:------|:-----|:------------|
| `MunicipioId` | `INT` | 🔑 PK · IDENTITY |
| `Nombre` | `NVARCHAR(150)` | NOT NULL |

---

### 🔵 `dbo.Comerciante` *(tabla central)*
| Campo | Tipo | Restricción |
|:------|:-----|:------------|
| `ComercianteId` | `INT` | 🔑 PK · IDENTITY |
| `NombreRazonSocial` | `NVARCHAR(255)` | NOT NULL |
| `MunicipioId` | `INT` | 🔗 FK → `Municipio` |
| `EstadoId` | `INT` | 🔗 FK → `Estado` |
| `Telefono` | `NVARCHAR(20)` | NULL |
| `CorreoElectronico` | `NVARCHAR(255)` | NULL |
| `FechaRegistro` | `DATE` | NOT NULL |
| `FechaActualizacion` | `DATETIME2` | NULL *(trigger)* |
| `UsuarioAuditoria` | `NVARCHAR(255)` | NULL *(trigger)* |

---

### 🔴 `dbo.Establecimiento`
| Campo | Tipo | Restricción |
|:------|:-----|:------------|
| `EstablecimientoId` | `INT` | 🔑 PK · IDENTITY |
| `Nombre` | `NVARCHAR(255)` | NOT NULL |
| `Ingresos` | `DECIMAL(18,2)` | NOT NULL |
| `NumeroEmpleados` | `INT` | NOT NULL |
| `ComercianteId` | `INT` | 🔗 FK → `Comerciante` |
| `FechaActualizacion` | `DATETIME2` | NULL *(trigger)* |
| `UsuarioAuditoria` | `NVARCHAR(255)` | NULL *(trigger)* |

---

## 🔷 Normalizaciones Aplicadas (3FN)

### 1 · Tabla `Rol`
**Sin normalizar:** `Rol NVARCHAR(50)` directo en `Usuario` → `'Administrador'` | `'Auxiliar de Registro'`  
**Con normalización:** Catálogo independiente con FK.  
**¿Por qué?** Evita texto repetido en cada fila de `Usuario`. Si el nombre del rol cambia, se actualiza **un solo registro** en el catálogo. Permite agregar nuevos roles sin alterar el esquema.

### 2 · Tabla `Municipio`
**Sin normalizar:** `Municipio NVARCHAR(150)` directo en `Comerciante` → `'Bogotá'` | `'bogota'` | `'Bogotá D.C.'`  
**Con normalización:** Catálogo independiente con FK.  
**¿Por qué?** Texto libre genera **inconsistencias graves**: variantes del mismo nombre se tratan como municipios distintos. El catálogo garantiza integridad referencial y confiabilidad en filtros y reportes.

### 3 · Tabla `Estado`
**Sin normalizar:** `Estado NVARCHAR(20)` directo en `Comerciante` → `'Activo'` | `'Inactivo'`  
**Con normalización:** Catálogo independiente con FK.  
**¿Por qué?** Centraliza los estados válidos del sistema. Facilita agregar nuevos estados y mantiene consistencia en las consultas y filtros del reporte.

---

## 🗂️ Orden de Ejecución de Scripts

> ⚠️ Los scripts **deben ejecutarse en este orden exacto**. Cada uno depende del anterior.

### `01` · `01_Crear_DatabaseTablesIndex.sql` — DDL

Crea la **base de datos** `AgremiacionComercio` y todas las **tablas** del modelo: `Rol`, `Usuario`, `Municipio`, `Estado`, `Comerciante` y `Establecimiento`. También define los **índices** para optimizar las consultas más frecuentes.

> 🔴 **Debe ejecutarse primero** — los demás scripts dependen de esta estructura.

---

### `02` · `02_Triggers_Auditoria.sql` — TRIGGER

Crea los **triggers de auditoría** `trg_Comerciante_Auditoria` y `trg_Establecimiento_Auditoria`. Deben crearse **después de las tablas** (Script 01) ya que los triggers se asocian directamente a ellas.

> Sin este script los campos `FechaActualizacion` y `UsuarioAuditoria` no se poblarán automáticamente.

---

### `03` · `03_Datos_Semilla.sql` — DML

Inserta los **datos iniciales** necesarios para el funcionamiento del sistema:
- Catálogos: `Rol`, `Estado`, `Municipio`
- **2 usuarios** (uno por cada rol)
- **5 comerciantes**
- **10 establecimientos**

> Debe ejecutarse después de los triggers para que los campos de auditoría se pueblen automáticamente al insertar.

---

### `04` · `04_SP_ReporteComerciantes.sql` — SP · FUNCTION

Crea la función auxiliar `fn_ObtenerResumenEstablecimientos` y el procedimiento almacenado `sp_ReporteComerciantes`. Debe ejecutarse de **último** ya que depende de que las tablas y los datos semilla existan previamente.

```sql
-- Para ejecutar el reporte:
EXEC dbo.sp_ReporteComerciantes;
```

---

## ⚡ Triggers de Auditoría

### `trg_Comerciante_Auditoria`
- **Tabla:** `dbo.Comerciante`
- **Evento:** `AFTER INSERT, UPDATE`
- **¿Qué hace?** Cada vez que se **inserta o modifica** un comerciante, actualiza automáticamente `FechaActualizacion` con la fecha y hora exacta del momento, y `UsuarioAuditoria` con el usuario de la sesión SQL Server activa (`SYSTEM_USER`).

### `trg_Establecimiento_Auditoria`
- **Tabla:** `dbo.Establecimiento`
- **Evento:** `AFTER INSERT, UPDATE`
- **¿Qué hace?** Cada vez que se **inserta o modifica** un establecimiento, actualiza automáticamente `FechaActualizacion` con la fecha y hora exacta del momento, y `UsuarioAuditoria` con el usuario de la sesión SQL Server activa (`SYSTEM_USER`).

### Campos de Auditoría — Detalle

| Campo | Tipo | Descripción |
|:------|:-----|:------------|
| `FechaActualizacion` | `DATETIME2(0)` NULL | Fecha y hora exacta del último cambio. Poblado automáticamente por el trigger usando `GETDATE()`. Nunca se debe ingresar manualmente. |
| `UsuarioAuditoria` | `NVARCHAR(255)` NULL | Nombre del usuario de SQL Server que ejecutó la operación. Poblado con `SYSTEM_USER`. En producción puede reemplazarse por el usuario de la aplicación enviado desde el backend. |

📌 **Tablas con campos de auditoría:** `dbo.Comerciante` · `dbo.Establecimiento`

---

## 📊 Stored Procedure — Reporte de Comerciantes

### Arquitectura del reporte

```
sp_ReporteComerciantes
        │
        └──► fn_ObtenerResumenEstablecimientos()
                    (INLINE TABLE-VALUED FUNCTION)
                    Retorna: ComercianteId, CantidadEstablecimientos,
                             TotalIngresos, CantidadEmpleados
```

**¿Por qué se creó la función auxiliar?**  
Encapsula los cálculos de `COUNT`, `SUM` de ingresos y `SUM` de empleados agrupados por comerciante. Separarlo en una función independiente la hace **reutilizable** en otras consultas o procedimientos futuros, y mantiene el SP principal **limpio y legible**.

### Columnas retornadas

**Datos del Comerciante**
- 📌 `Nombre / Razón Social`
- 📌 `Municipio`
- 📌 `Teléfono`
- 📌 `Correo Electrónico`
- 📌 `Fecha de Registro`
- 📌 `Estado`

**Calculados por la Función**
- 🔢 `Cantidad de Establecimientos`
- 💰 `Total Ingresos`
- 👥 `Cantidad de Empleados`

### Detalles Técnicos

| Aspecto | Detalle |
|:--------|:--------|
| **Filtro** | Solo comerciantes `Activos` |
| **Orden** | `DESC` por cantidad de establecimientos |
| **JOIN** | `LEFT JOIN` con la función para incluir comerciantes sin establecimientos |
| **Nulos** | `ISNULL` muestra `0` o `'N/A'` en lugar de vacíos |

---

## ⚠️ Nota de Seguridad

> **Campo `Usuario.Contrasena`**

El campo `Contrasena NVARCHAR(255)` está definido para almacenar el **hash** de la contraseña, **no el texto plano**. El hashing debe realizarse en la **capa de aplicación** (backend) antes de persistir el dato, usando algoritmos como `bcrypt`, `Argon2` o `PBKDF2`. SQL Server únicamente almacena el resultado.

> ❌ **Nunca se debe guardar ni comparar contraseñas en texto plano.**

---

## 📖 Leyenda

| Símbolo | Significado |
|:--------|:------------|
| 🔑 | PK · Llave Primaria (IDENTITY) |
| 🔗 | FK · Llave Foránea |
| `NULL` | Campo Opcional |
| *italics* | Campo de Auditoría (gestionado por Trigger) |

---

<div align="center">

Creado por **Juan David Escobar** · 2026

![SQL Server](https://img.shields.io/badge/Microsoft-SQL%20Server-CC2927?style=flat-square&logo=microsoftsqlserver&logoColor=white)
![T-SQL](https://img.shields.io/badge/Language-T--SQL-00d4ff?style=flat-square)
![3NF](https://img.shields.io/badge/Normalización-3FN-7c3aed?style=flat-square)

</div>
