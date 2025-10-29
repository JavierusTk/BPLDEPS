# BPLDeps - Analizador de Dependencias BPL

Utilidad de línea de comandos para analizar dependencias en tiempo de ejecución de archivos BPL (Borland Package Library) de Delphi.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Delphi](https://img.shields.io/badge/Delphi-12%20Athens-blue.svg)](https://www.embarcadero.com/products/delphi)
[![Platform](https://img.shields.io/badge/platform-Windows-lightgrey.svg)](https://www.microsoft.com/windows)

[English](README.md)

## Características

- **Dependencias directas**: Muestra solo los packages que el BPL importa directamente
- **Dependencias recursivas**: Muestra todas las dependencias transitivas (por defecto)
- **Vista en árbol**: Visualiza la jerarquía completa de dependencias
- **Modo verbose**: Muestra rutas completas y resumen de encontrados/no encontrados
- **Búsqueda automática**: Puede encontrar archivos BPL en rutas comunes si solo proporcionas el nombre

## ¿Por qué BPLDeps?

Al trabajar con packages de Delphi, el diálogo "Project Information" del IDE muestra todas las dependencias pero:
- ❌ No puedes copiar/pegar la lista
- ❌ No es automatizable
- ❌ No muestra dónde está ubicado cada BPL
- ❌ No distingue entre dependencias encontradas y faltantes

**BPLDeps resuelve todos estos problemas** leyendo directamente la Tabla de Importaciones PE y proporcionando:
- ✅ Salida copiable/pegable
- ✅ Scriptable para CI/CD
- ✅ Información de ruta completa para cada dependencia
- ✅ Identificación clara de dependencias faltantes
- ✅ Estadísticas (total/encontrados/no encontrados)

## Instalación

### Binario Pre-compilado

Descarga la última versión desde [Releases](https://github.com/yourusername/bpldeps/releases) y extrae `BPLDeps.exe` a un directorio en tu PATH.

### Compilar desde Código Fuente

Requiere Embarcadero Delphi 12 (Athens) o posterior.

```bash
git clone https://github.com/yourusername/bpldeps.git
cd bpldeps
msbuild BPLDeps.dproj /p:Config=Release
```

El ejecutable compilado estará en el directorio del proyecto.

## Uso

```bash
BPLDeps <archivo.bpl> [opciones]
```

### Opciones

- `-r` - Mostrar dependencias recursivas (por defecto)
- `-d` - Mostrar solo dependencias directas
- `-t` - Mostrar como árbol
- `-v` - Modo verbose (mostrar rutas y resumen)

### Ejemplos

#### 1. Análisis básico (recursivo)

```bash
BPLDeps rtl290.bpl
```

Resultado:
```
Analyzing: rtl290.bpl
Full path: C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\rtl290.bpl

All dependencies (0):
```

#### 2. Solo dependencias directas

```bash
BPLDeps MyPackage.bpl -d
```

Muestra solo los packages que MyPackage importa directamente, sin dependencias transitivas.

#### 3. Vista en árbol

```bash
BPLDeps MyPackage.bpl -t
```

Resultado:
```
Dependency tree:

MyPackage.bpl
  rtl290.bpl
  vcl290.bpl
    rtl290.bpl
  dbrtl290.bpl
    rtl290.bpl
```

#### 4. Modo verbose (con rutas y resumen)

```bash
BPLDeps MyPackage.bpl -v
```

Resultado:
```
Analyzing: MyPackage.bpl
Full path: W:\BPL\290\MyPackage.bpl

All dependencies (73):

  BaseMAX290.bpl
    -> W:\BPL\290\BaseMAX290.bpl
  CustomPackage.bpl
    -> NOT FOUND
  rtl290.bpl
    -> C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\rtl290.bpl
  ...

Summary:
  Total dependencies: 73
  Found: 72
  Not found: 1
```

#### 5. Con ruta completa

```bash
BPLDeps "C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\vcl290.bpl"
```

#### 6. Solo nombre de archivo (búsqueda automática)

```bash
BPLDeps rtl290.bpl
```

La herramienta busca automáticamente en:
- Directorio actual
- Directorio del ejecutable
- Directorios bin de RAD Studio
- PATH del sistema

## Casos de Uso

### 1. Verificar requisitos de instalación del package

```bash
BPLDeps MyPackage.bpl -v > dependencias.txt
```

Obtiene la lista completa de archivos BPL requeridos para despliegue.

### 2. Encontrar dependencias circulares

```bash
BPLDeps PackageA.bpl -t
```

Si ves PackageA → PackageB → PackageA, tienes una dependencia circular.

### 3. Analizar impacto de cambios

Si modificas BaseMAX, puedes ver qué packages dependen de él:

```bash
for bpl in *.bpl; do
  echo "Checking $bpl..."
  BPLDeps "$bpl" | grep -q "BaseMAX" && echo "  → Depends on BaseMAX"
done
```

### 4. Comparar con declaración requires

El archivo `.dpk` solo lista requires directos. Usa BPLDeps para ver la lista completa real:

```bash
# Ver qué dice el código
grep "requires" MyPackage.dpk

# Ver qué necesita realmente el BPL compilado
BPLDeps MyPackage.bpl
```

### 5. Integración CI/CD

```bash
# Verificar dependencias faltantes en CI
BPLDeps MyPackage.bpl -v | grep "NOT FOUND" && exit 1
```

## Notas Técnicas

- Usa la API Windows `ImageHlp` para leer la Tabla de Importaciones PE
- Solo analiza dependencias de archivos `.bpl` (ignora DLLs del sistema)
- Requiere que los BPLs dependientes sean accesibles para análisis recursivo
- Si un BPL no se encuentra, lo reporta pero continúa con otros
- Thread-safe y maneja archivos bloqueados

## Cómo Funciona

BPLDeps analiza directamente el formato PE32 (Portable Executable):

1. Lee el encabezado DOS
2. Localiza los encabezados NT
3. Encuentra el Directorio de Importaciones
4. Itera a través de los Descriptores de Importación
5. Filtra solo archivos `.bpl`
6. Analiza recursivamente cada dependencia encontrada

Este enfoque es más confiable que analizar archivos de texto y muestra las **dependencias reales en tiempo de ejecución**, no solo lo que está declarado en el código fuente.

## Salida Estándar

Toda la salida va a stdout, permitiendo:

```bash
# Guardar en archivo
BPLDeps MyPackage.bpl > deps.txt

# Contar dependencias
BPLDeps MyPackage.bpl | grep -c "\.bpl"

# Filtrar packages específicos
BPLDeps MyPackage.bpl | grep "rtl\|vcl"

# Pipeline con otras herramientas
BPLDeps *.bpl | sort | uniq
```

## Diferencias con el IDE

| Característica | Diálogo IDE | BPLDeps |
|----------------|-------------|---------|
| Copiar/Pegar | ❌ | ✅ |
| Mostrar Rutas | ❌ | ✅ (con -v) |
| Identificar Faltantes | ❌ | ✅ (con -v) |
| Scriptable | ❌ | ✅ |
| Vista Árbol | ❌ | ✅ (con -t) |
| Estadísticas | ❌ | ✅ (con -v) |
| Directas vs Todas | ❌ | ✅ |

## Requisitos

- Windows (usa formato PE de Windows)
- No requiere DLLs externas (ejecutable standalone)
- Funciona con cualquier versión de Delphi (analiza BPLs compilados, no código fuente)

## Contribuciones

¡Las contribuciones son bienvenidas! Por favor, siéntete libre de enviar un Pull Request.

## Licencia

Licencia MIT - ver archivo [LICENSE](LICENSE) para detalles.

## Autor

Creado para la comunidad de desarrollo Delphi.

---

**Versión**: 1.0.0
**Última Actualización**: 2024
