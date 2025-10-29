# Contributing to BPLDeps

Thank you for considering contributing to BPLDeps! This document provides guidelines for contributing to this project.

## How to Contribute

### Reporting Bugs

If you find a bug, please create an issue on GitHub with:
- A clear title and description
- Steps to reproduce the issue
- Expected vs actual behavior
- BPL file details (if applicable)
- Your environment (Delphi version, Windows version)

### Suggesting Features

Feature suggestions are welcome! Please create an issue describing:
- The feature you'd like to see
- Why it would be useful
- How you envision it working

### Pull Requests

1. **Fork the repository** and create your branch from `main`
2. **Make your changes** following the code style guidelines
3. **Test your changes** thoroughly
4. **Update documentation** if needed (README, comments, etc.)
5. **Submit a pull request** with a clear description of changes

## Development Setup

### Prerequisites

- Embarcadero Delphi 12 (Athens) or later
- Git for version control
- Basic knowledge of Delphi and Windows PE format

### Building

```bash
git clone https://github.com/yourusername/bpldeps.git
cd bpldeps
msbuild BPLDeps.dproj /p:Config=Release
```

### Testing

Test your changes with various BPL files:

```bash
# Test basic functionality
BPLDeps.exe rtl290.bpl

# Test verbose mode
BPLDeps.exe vcl290.bpl -v

# Test tree view
BPLDeps.exe vcl290.bpl -t

# Test with missing dependencies
BPLDeps.exe YourCustomPackage.bpl -v
```

## Code Style Guidelines

### Pascal/Delphi Code

- Use **clear, descriptive names** for variables and functions
- Add **comments for complex logic**, especially PE parsing
- Follow **Delphi naming conventions**:
  - `T` prefix for types (`TDependencyList`)
  - Camel case for identifiers (`GetBplPath`)
  - Clear parameter names (`const FileName: string`)

### Code Organization

- Keep functions **focused on a single task**
- Use **meaningful procedure/function names**
- Group related functionality together
- Add blank lines between logical sections

### Comments

- Use `//` for single-line comments
- Explain **why**, not just **what**
- Update comments when code changes
- English language for all comments

### Example

```pascal
// Good
function GetBplPath(const FileName: string): string;
// Search in common directories for the BPL file
// Returns full path if found, empty string otherwise

// Not so good
function GBP(const FN: string): string;
// Get path
```

## Documentation

- Update README.md if you change functionality
- Update README-ES.md (Spanish version) to match
- Add examples for new features
- Keep documentation accurate and up-to-date

## Commit Messages

Use clear, descriptive commit messages:

```bash
# Good
git commit -m "Add support for Win64 BPL files"
git commit -m "Fix crash when BPL has no imports"
git commit -m "Improve error messages for missing files"

# Not so good
git commit -m "fix bug"
git commit -m "updates"
```

## Release Process

1. Update version number in README files
2. Update CHANGELOG.md (if exists)
3. Create a tagged release
4. Build binaries for distribution
5. Update GitHub release with binaries and notes

## Questions?

Feel free to:
- Open an issue for questions
- Start a discussion on GitHub
- Contact maintainers

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Code of Conduct

- Be respectful and professional
- Welcome newcomers
- Focus on constructive feedback
- Help maintain a positive community

Thank you for contributing! 🎉
