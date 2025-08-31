# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Build & Test

```bash
# Full build pipeline (recommended)
.\build.ps1                    # Windows PowerShell script: restore → build → test

# Individual commands
dotnet restore                 # Restore dependencies
dotnet build -c Release       # Build solution
dotnet test -c Release        # Run all tests

# Run specific test project
dotnet test test/Wangkanai.Nation.Tests.csproj

# Run benchmarks
dotnet run --project benchmark/Wangkanai.Nation.Benchmark.csproj
```

### Project Structure

- **Solution**: `Nation.slnx` (Visual Studio solution format)
- **Main Library**: `src/Wangkanai.Nation.csproj` (.NET 9, targets NuGet package)
- **Tests**: `test/Wangkanai.Nation.Tests.csproj` (xUnit-based)
- **Benchmarks**: `benchmark/Wangkanai.Nation.Benchmark.csproj`

## Architecture Overview

### Domain-Driven Design Structure

The codebase follows DDD principles with a clear entity hierarchy:

```
Domain/
├── Entity<T>           # Abstract base class with identity, equality, and transient state management
├── IEntity<T>          # Entity interface contract

Models/
├── Country             # Root geographical entity (sealed class)
├── Division            # Abstract administrative subdivision base
│   ├── Province, State, Region, County, Canton...  # Concrete division types
├── Urban               # Abstract urban area base
│   ├── City, Town, Village, District...            # Concrete urban types

Configuration/
├── CountryConfiguration     # EF Core entity configuration
├── DivisionConfiguration   # EF Core configuration for all division types
├── UrbanConfiguration      # EF Core configuration for urban entities

Seeds/
└── Thailand/ProvinceSeed   # Pre-built seed data for provinces
```

### Key Architectural Decisions

1. **Entity Base Class**: All domain entities inherit from `Entity<T>` providing ID-based equality, hash code generation, and transient state checking
2. **Inheritance Strategy**: Uses abstract base classes (`Division`, `Urban`) with concrete implementations for different geographical subdivision types
3. **Entity Framework Integration**: Dedicated configuration classes for each entity type with proper table mapping
4. **Seed Data Pattern**: Structured seed data classes for bootstrapping databases with real-world geographical data
5. **Strong Typing**: All entities are strongly typed with proper constructors and immutable IDs

### Entity Relationships

- `Country` → (1:many) → `Division` → (1:many) → `Urban`
- Each entity maintains foreign key relationships via integer IDs
- All entities include native language names alongside English names
- ISO codes are used consistently for standardized geographical identification

## Key Patterns

### Entity Creation Pattern

```csharp
// Preferred: Use constructor with all required properties
var thailand = new Country(764, "TH", 66, "Thailand", "ประเทศไทย", 69950850);
var bangkok = new Province(1, 764, "TH-10", "Bangkok", "กรุงเทพมหานคร");

// EF Core configurations handle database mapping automatically
```

### Seed Data Usage

```csharp
// Access pre-built datasets for common use cases
var provinces = ProvinceSeed.Dataset;
context.Divisions.AddRange(provinces);
```

## Testing Framework

- **Test Runner**: xUnit with Visual Studio test integration
- **Coverage**: Coverlet collector for code coverage analysis
- **CI Integration**: GitHub Actions with SonarCloud analysis

## Build Configuration

- **Target Framework**: .NET 9.0
- **Language**: C# with latest language features enabled
- **Nullable**: Enabled throughout the codebase
- **Warnings**: Treated as errors (except NU1605, CS8618)
- **Package**: Published to NuGet as `Wangkanai.Nation`