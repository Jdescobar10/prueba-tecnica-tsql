# FULLSTACK · T-SQL
## Prueba Técnica — Agremiación Nacional de Comercio

> **Base de datos:** `AgremiacionComercio` · **Motor:** SQL Server · **Lenguaje:** T-SQL  
> **Autor:** Juan David Escobar · 2026

---

## 📋 Descripción

Sistema de base de datos diseñado para centralizar y gestionar la información de comerciantes y sus establecimientos, apoyando los procesos operativos esenciales de la agremiación nacional de comercio.

---

## 📁 Orden de Ejecución de Scripts

> ⚠️ Los scripts **deben ejecutarse en el orden indicado**. Cada uno depende del anterior.

| # | Archivo | Tipo | Descripción |
|---|---------|------|-------------|
| 01 | `01_Crear_DatabaseTablesIndex.sql` | DDL | Crea la base de datos, todas las tablas e índices |
| 02 | `02_Triggers_Auditoria.sql` | TRIGGER | Crea los triggers de auditoría automática |
| 03 | `03_Datos_Semilla.sql` | DML | Inserta los datos iniciales del sistema |
| 04 | `04_SP_ReporteComerciantes.sql` | SP · FUNCTION | Crea la función auxiliar y el stored procedure del reporte |

---

## 🗄 Modelo de Datos

### Tablas

| Tabla | Descripción |
|-------|-------------|
| `dbo.Rol` | Catálogo de roles: `Administrador` y `Auxiliar de Registro` |
| `dbo.Usuario` | Usuarios del sistema con correo, contraseña y rol |
| `dbo.Municipio` | Catálogo de municipios |
| `dbo.Estado` | Catálogo de estados: `Activo` e `Inactivo` |
| `dbo.Comerciante` | Comerciantes registrados con campos de auditoría |
| `dbo.Establecimiento` | Establecimientos asociados a cada comerciante con campos de auditoría |

### Relaciones

```
Rol           ──(1:N)──► Usuario
Estado        ──(1:N)──► Comerciante
Municipio     ──(1:N)──► Comerciante
Comerciante   ──(1:N)──► Establecimiento
```

---

## 🔷 Normalizaciones Aplicadas — 3FN

Se aplicó **Tercera Forma Normal (3FN)** en tres entidades para eliminar dependencias transitivas y evitar valores de dominio controlado como texto libre.

### 1 · Tabla `Rol`
- **Sin normalizar:** `Rol NVARCHAR(50)` en la tabla `Usuario`
- **¿Por qué?** Evita texto repetido en cada fila. Si el nombre del rol cambia, se actualiza un solo registro en el catálogo. Permite agregar nuevos roles sin alterar el esquema.

### 2 · Tabla `Municipio`
- **Sin normalizar:** `Municipio NVARCHAR(150)` en la tabla `Comerciante`
- **¿Por qué?** Texto libre genera inconsistencias graves: `'Bogotá'`, `'bogota'`, `'Bogotá D.C.'` serían tres municipios distintos. El catálogo garantiza integridad referencial y confiabilidad en filtros y reportes.

### 3 · Tabla `Estado`
- **Sin normalizar:** `Estado NVARCHAR(20)` en la tabla `Comerciante`
- **¿Por qué?** Si el negocio requiere estados nuevos como `'Suspendido'`, solo se inserta un registro. Con texto plano habría que modificar el esquema y agregar un `CHECK constraint`.

---

## ⚡ Triggers de Auditoría

### `trg_Comerciante_Auditoria`
- **Tabla:** `dbo.Comerciante`
- **Evento:** `AFTER INSERT, UPDATE`
- **¿Qué hace?** Actualiza automáticamente `FechaActualizacion` con `GETDATE()` y `UsuarioAuditoria` con `SYSTEM_USER` en cada inserción o modificación.

### `trg_Establecimiento_Auditoria`
- **Tabla:** `dbo.Establecimiento`
- **Evento:** `AFTER INSERT, UPDATE`
- **¿Qué hace?** Igual que el anterior, pero sobre la tabla `Establecimiento`.

### Campos de auditoría

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `FechaActualizacion` | `DATETIME2(0)` | Fecha y hora exacta de la última operación. Poblado por `GETDATE()` |
| `UsuarioAuditoria` | `NVARCHAR(255)` | Usuario de la sesión SQL Server activa. Poblado por `SYSTEM_USER` |

> Ambos campos están presentes en `dbo.Comerciante` y `dbo.Establecimiento`.

---

## 📊 Reporte de Comerciantes

### Función auxiliar: `fn_ObtenerResumenEstablecimientos`
- **Tipo:** `INLINE TABLE-VALUED FUNCTION`
- **Retorna:** `(ComercianteId, CantidadEstablecimientos, TotalIngresos, CantidadEmpleados)`
- **¿Por qué se creó separada?** Encapsula los cálculos `COUNT` y `SUM` agrupados por comerciante. Al estar en una función independiente es **reutilizable** en otras consultas y mantiene el SP principal limpio y legible.

### Stored Procedure: `sp_ReporteComerciantes`

```sql
EXEC dbo.sp_ReporteComerciantes;
```

**Columnas retornadas:**

| Campo | Origen |
|-------|--------|
| `NombreRazonSocial` | Comerciante |
| `Municipio` | Catálogo Municipio |
| `Telefono` | Comerciante |
| `CorreoElectronico` | Comerciante |
| `FechaRegistro` | Comerciante |
| `Estado` | Catálogo Estado |
| `CantidadEstablecimientos` | Calculado por la función |
| `TotalIngresos` | Calculado por la función |
| `CantidadEmpleados` | Calculado por la función |

**Detalles técnicos:**
- **Filtro:** Solo comerciantes `Activos`
- **Orden:** `DESC` por `CantidadEstablecimientos`
- **JOIN:** `INNER JOIN` con la función auxiliar
- **Alias:** Sin espacios para compatibilidad con `EF Core FromSql()`

---

## 🌱 Datos Semilla

| Entidad | Cantidad |
|---------|----------|
| Usuarios | 2 (uno por cada rol) |
| Comerciantes | 5 (4 activos, 1 inactivo) |
| Establecimientos | 10 (distribución aleatoria por comerciante) |

---

## 🔐 Nota de Seguridad

El campo `Usuario.Contrasena NVARCHAR(255)` está definido para almacenar el **hash** de la contraseña, **no el texto plano**. El hashing debe realizarse en la **capa de aplicación** (backend) antes de persistir el dato, usando algoritmos como `bcrypt`, `Argon2` o `PBKDF2`. SQL Server únicamente almacena el resultado.

---

## 📄 Documentación

El archivo `00_AgremiacionComercio.html` contiene la documentación visual completa del proyecto incluyendo el diagrama Entidad-Relación, orden de scripts, normalizaciones, triggers y reporte de comerciantes.
