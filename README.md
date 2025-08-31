## Nation: Seed your dataset with actual country data

[![NuGet Version](https://img.shields.io/nuget/v/wangkanai.nation)](https://www.nuget.org/packages/wangkanai.nation)
[![NuGet Pre Release](https://img.shields.io/nuget/vpre/wangkanai.nation)](https://www.nuget.org/packages/wangkanai.nation)

[![.NET](https://github.com/wangkanai/nation/actions/workflows/dotnet.yml/badge.svg)](https://github.com/wangkanai/nation/actions/workflows/dotnet.yml)
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=wangkanai_nation&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=wangkanai_nation)

[![Open Collective](https://img.shields.io/badge/open%20collective-support%20me-3385FF.svg)](https://opencollective.com/wangkanai)
[![Patreon](https://img.shields.io/badge/patreon-support%20me-d9643a.svg)](https://www.patreon.com/wangkanai)
[![GitHub](https://img.shields.io/github/license/wangkanai/nation)](https://github.com/wangkanai/nation/blob/main/LICENSE)

A comprehensive .NET library providing structured data for countries, divisions, and urban areas. Perfect for seeding databases, building location-aware applications, and working with geographical data in your .NET projects.

## Features

🌍 **Countries**: Complete country data with ISO codes, names, and population  
🗺️ **Divisions**: Administrative divisions (provinces, states, regions, etc.)  
🏙️ **Urban Areas**: Cities, towns, districts, and other urban classifications  
📊 **Entity Framework Support**: Built-in configurations for easy database integration  
🎯 **Type-Safe**: Strongly-typed entities with proper inheritance  
⚡ **Performance**: Optimized for both memory usage and query performance  

## Installation

Install the NuGet package:

```bash
dotnet add package Wangkanai.Nation
```

## Quick Start

### Basic Usage

```csharp
using Wangkanai.Nation.Models;

// Create a country
var thailand = new Country(764, "TH", 69950850, "Thailand", "ประเทศไทย");

// Create a division (province)
var bangkok = new Province(1, 764, "TH-10", "Bangkok", "กรุงเทพมหานคร");

// Create an urban area
var district = new Urban { Name = "Watthana", Native = "วัฒนา", Iso = "10110" };
```

### Entity Framework Integration

```csharp
using Microsoft.EntityFrameworkCore;
using Wangkanai.Nation.Models;

public class ApplicationDbContext : DbContext
{
    public DbSet<Country> Countries { get; set; }
    public DbSet<Division> Divisions { get; set; }
    public DbSet<Urban> Urbans { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Apply Nation configurations
        modelBuilder.ApplyConfiguration(new CountryConfiguration());
        modelBuilder.ApplyConfiguration(new DivisionConfiguration());
        modelBuilder.ApplyConfiguration(new UrbanConfiguration());
    }
}
```

### Seeding Data

```csharp
// Use built-in seed data
var provinces = ProvinceSeed.Dataset;
foreach (var province in provinces)
{
    context.Divisions.Add(province);
}
await context.SaveChangesAsync();
```

## Architecture

The library is built with Domain-Driven Design principles:

- **Entities**: `Country`, `Division`, `Urban` with proper inheritance from `Entity<T>`
- **Value Objects**: Strongly-typed identifiers and codes  
- **Configurations**: Entity Framework configurations for each model
- **Seeds**: Pre-built datasets for common scenarios

## Supported Administrative Levels

### Countries
- ISO 3166-1 numeric and alpha-2 codes
- Native and English names
- Population data

### Divisions (Administrative Subdivisions)
- **States** (US, Australia)
- **Provinces** (Canada, Thailand, China)
- **Regions** (France, Italy)  
- **Counties** (UK, Ireland)
- **Cantons** (Switzerland)
- And many more...

### Urban Areas
- **Cities** and **Towns**
- **Districts** and **Wards** 
- **Villages** and **Hamlets**
- **Administrative Areas**

## Contributing

We welcome contributions! Please see our [Contributing Guidelines](https://github.com/wangkanai/nation/blob/main/CONTRIBUTING.md) for details.

### Development

```bash
# Clone the repository
git clone https://github.com/wangkanai/nation.git
cd nation

# Build the solution
dotnet build

# Run tests
dotnet test

# Run benchmarks
dotnet run --project benchmark
```

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## Support

If you find this project useful, please consider supporting it:

- ⭐ Star the repository
- 💰 [Sponsor on GitHub](https://github.com/sponsors/wangkanai)
- ☕ [Buy me a coffee](https://opencollective.com/wangkanai)

## Related Projects

- [Wangkanai Detection](https://github.com/wangkanai/Detection) - Browser & OS detection
- [Wangkanai Responsive](https://github.com/wangkanai/Responsive) - Responsive web development
- [Wangkanai Analytics](https://github.com/wangkanai/Analytics) - Web analytics

---

Built with ❤️ by [Sarin Na Wangkanai](https://github.com/wangkanai) and [contributors](https://github.com/wangkanai/nation/graphs/contributors).