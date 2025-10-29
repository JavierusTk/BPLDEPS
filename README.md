# BPLDeps - BPL Dependency Analyzer

A command-line utility to analyze runtime dependencies of Delphi BPL (Borland Package Library) files.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Delphi](https://img.shields.io/badge/Delphi-12%20Athens-blue.svg)](https://www.embarcadero.com/products/delphi)
[![Platform](https://img.shields.io/badge/platform-Windows-lightgrey.svg)](https://www.microsoft.com/windows)

[Español](README-ES.md)

## Features

- **Direct dependencies**: Shows only packages that the BPL imports directly
- **Recursive dependencies**: Shows all transitive dependencies (default)
- **Tree view**: Visualizes the complete dependency hierarchy
- **Verbose mode**: Shows full paths and found/not found summary
- **Automatic search**: Can find BPL files in common paths if you only provide the name

## Why BPLDeps?

When working with Delphi packages, the IDE's "Project Information" dialog shows all dependencies but:
- ❌ You cannot copy/paste the list
- ❌ It's not automatable
- ❌ It doesn't show where each BPL is located
- ❌ It doesn't distinguish between found and missing dependencies

**BPLDeps solves all these problems** by reading the PE Import Table directly and providing:
- ✅ Copyable/pasteable output
- ✅ Scriptable for CI/CD
- ✅ Full path information for each dependency
- ✅ Clear identification of missing dependencies
- ✅ Statistics (total/found/not found)

## Installation

### Pre-built Binary

Download the latest release from [Releases](https://github.com/yourusername/bpldeps/releases) and extract `BPLDeps.exe` to a directory in your PATH.

### Build from Source

Requires Embarcadero Delphi 12 (Athens) or later.

```bash
git clone https://github.com/yourusername/bpldeps.git
cd bpldeps
msbuild BPLDeps.dproj /p:Config=Release
```

The compiled executable will be in the project directory.

## Usage

```bash
BPLDeps <file.bpl> [options]
```

### Options

- `-r` - Show recursive dependencies (default)
- `-d` - Show only direct dependencies
- `-t` - Show as tree
- `-v` - Verbose mode (show paths and summary)

### Examples

#### 1. Basic analysis (recursive)

```bash
BPLDeps rtl290.bpl
```

Output:
```
Analyzing: rtl290.bpl
Full path: C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\rtl290.bpl

All dependencies (0):
```

#### 2. Direct dependencies only

```bash
BPLDeps MyPackage.bpl -d
```

Shows only packages that MyPackage imports directly, without transitive dependencies.

#### 3. Tree view

```bash
BPLDeps MyPackage.bpl -t
```

Output:
```
Dependency tree:

MyPackage.bpl
  rtl290.bpl
  vcl290.bpl
    rtl290.bpl
  dbrtl290.bpl
    rtl290.bpl
```

#### 4. Verbose mode (with paths and summary)

```bash
BPLDeps MyPackage.bpl -v
```

Output:
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

#### 5. With full path

```bash
BPLDeps "C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\vcl290.bpl"
```

#### 6. Just filename (automatic search)

```bash
BPLDeps rtl290.bpl
```

The tool automatically searches in:
- Current directory
- Executable directory
- RAD Studio bin directories
- System PATH

## Use Cases

### 1. Verify package installation requirements

```bash
BPLDeps MyPackage.bpl -v > dependencies.txt
```

Get the complete list of required BPL files for deployment.

### 2. Find circular dependencies

```bash
BPLDeps PackageA.bpl -t
```

If you see PackageA → PackageB → PackageA, you have a circular dependency.

### 3. Analyze impact of changes

If you modify BaseMAX, you can see which packages depend on it:

```bash
for bpl in *.bpl; do
  echo "Checking $bpl..."
  BPLDeps "$bpl" | grep -q "BaseMAX" && echo "  → Depends on BaseMAX"
done
```

### 4. Compare with requires declaration

The `.dpk` file only lists direct requires. Use BPLDeps to see the complete real list:

```bash
# See what the code says
grep "requires" MyPackage.dpk

# See what the compiled BPL really needs
BPLDeps MyPackage.bpl
```

### 5. CI/CD Integration

```bash
# Check for missing dependencies in CI
BPLDeps MyPackage.bpl -v | grep "NOT FOUND" && exit 1
```

## Technical Notes

- Uses Windows `ImageHlp` API to read the PE Import Table
- Only analyzes `.bpl` file dependencies (ignores system DLLs)
- Requires dependent BPLs to be accessible for recursive analysis
- If a BPL is not found, it reports it but continues with others
- Thread-safe and handles locked files

## How It Works

BPLDeps directly parses the PE32 (Portable Executable) format:

1. Reads the DOS header
2. Locates the NT headers
3. Finds the Import Directory
4. Iterates through Import Descriptors
5. Filters only `.bpl` files
6. Recursively analyzes each found dependency

This approach is more reliable than parsing text files and shows the **actual runtime dependencies**, not just what's declared in source code.

## Standard Output

All output goes to stdout, allowing:

```bash
# Save to file
BPLDeps MyPackage.bpl > deps.txt

# Count dependencies
BPLDeps MyPackage.bpl | grep -c "\.bpl"

# Filter specific packages
BPLDeps MyPackage.bpl | grep "rtl\|vcl"

# Pipeline with other tools
BPLDeps *.bpl | sort | uniq
```

## Differences from IDE

| Feature | IDE Dialog | BPLDeps |
|---------|-----------|---------|
| Copy/Paste | ❌ | ✅ |
| Show Paths | ❌ | ✅ (with -v) |
| Identify Missing | ❌ | ✅ (with -v) |
| Scriptable | ❌ | ✅ |
| Tree View | ❌ | ✅ (with -t) |
| Statistics | ❌ | ✅ (with -v) |
| Direct vs All | ❌ | ✅ |

## Requirements

- Windows (uses Windows PE format)
- No external DLLs required (standalone executable)
- Works with any Delphi version (analyzes compiled BPLs, not source)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Author

Created for the Delphi development community.

---

**Version**: 1.0.0
**Last Updated**: 2024
