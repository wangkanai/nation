# Nation Library Documentation

A comprehensive .NET library providing structured data for countries, divisions, and urban areas. Perfect for seeding databases, building location-aware applications, and working with geographical data in your .NET projects.

## Documentation Index

### Getting Started
- **[Getting Started Guide](Getting_Started_Guide.md)** - Installation, basic usage, and initial setup
- **[API Reference](API_Reference.md)** - Complete API documentation for all classes and methods

### Advanced Topics  
- **[Advanced Usage](Advanced_Usage.md)** - EF Core integration patterns, performance optimization, and custom extensions
- **[Domain Model Structure](Domain_Model_Structure.md)** - Deep dive into the domain design and architectural patterns

### Technical Reference
- **[Project Architecture Overview](Project_Architecture_Overview.md)** - Understanding the internal structure, build system, and design decisions

## Quick Reference

### Core Entities

| Entity Type | Description | Example Usage |
|-------------|-------------|---------------|
| `Country` | Sovereign nations with ISO codes | `new Country(764, "TH", 66, "Thailand", "ไทย")` |
| `Division` | Administrative subdivisions | `new Province(1, 764, "TH-10", "Bangkok", "กรุงเทพมหานคร")` |
| `Urban` | Cities, towns, and urban areas | `new City { Name = "Bangkok", Native = "กรุงเทพฯ" }` |

### Key Features

- **🌍 Complete Geographical Hierarchy**: Countries → Divisions → Urban Areas
- **📊 Entity Framework Ready**: Built-in configurations and relationships
- **🎯 Type-Safe**: Strongly-typed entities with proper inheritance
- **⚡ Performance Optimized**: Efficient database queries and memory usage
- **🌐 Unicode Support**: Native language names with proper encoding
- **📦 Seed Data Included**: Pre-built datasets for rapid development

### Installation

```bash
dotnet add package Wangkanai.Nation
```

### Basic Usage

```csharp
using Wangkanai.Nation.Models;
using Wangkanai.Nation.Seeds;

// Use seed data
var countries = CountrySeed.Dataset;
var provinces = ProvinceSeed.Dataset;

// Create entities
var thailand = new Country(764, "TH", 66, "Thailand", "ไทย", 71_652_176);
var bangkok = new Province(1, 764, "TH-10", "Bangkok", "กรุงเทพมหานคร", 5_692_284);
```

### Entity Framework Integration

```csharp
public class ApplicationDbContext : DbContext
{
    public DbSet<Country> Countries { get; set; }
    public DbSet<Division> Divisions { get; set; }
    public DbSet<Urban> Urbans { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfiguration(new CountryConfiguration());
        modelBuilder.ApplyConfiguration(new DivisionConfiguration());
        modelBuilder.ApplyConfiguration(new UrbanConfiguration());
    }
}
```

## Architecture Overview

### Domain-Driven Design

The library follows DDD principles with a clear entity hierarchy:

```
Entity<T> (Abstract Base)
├── Country (Sealed)
├── Division (Abstract)
│   ├── Province, State, Region, County...
└── Urban (Abstract)
    ├── City, Town, Village, Ward...
```

### Supported Administrative Types

**Countries**: 195+ sovereign nations with ISO 3166-1 codes  
**Divisions**: 25+ administrative subdivision types (provinces, states, regions, etc.)  
**Urban Areas**: 7+ urban settlement types (cities, towns, villages, etc.)

### Key Design Principles

1. **Generic Identity**: Type-safe entity identifiers with `Entity<T>` base class
2. **Inheritance Hierarchy**: Abstract base classes with concrete implementations
3. **Value Equality**: ID-based equality with proper hash code generation
4. **Transient Detection**: Built-in support for new vs. persisted entities
5. **Unicode Support**: Native language names with proper encoding

## Contributing

We welcome contributions! Areas where help is needed:

- **Seed Data**: Additional country and division datasets
- **Entity Types**: New administrative division types from various countries
- **Documentation**: Usage examples and best practices
- **Testing**: Unit tests and integration tests
- **Performance**: Query optimization and benchmarking

## License

This project is licensed under the Apache License 2.0. See the [LICENSE](../LICENSE) file for details.

## Support

- 📖 **Documentation**: Browse the guides above for detailed information
- 🐛 **Issues**: Report bugs and feature requests on [GitHub](https://github.com/wangkanai/nation/issues)  
- 💡 **Discussions**: Ask questions in [GitHub Discussions](https://github.com/wangkanai/nation/discussions)
- ⭐ **Star**: Show support by starring the [repository](https://github.com/wangkanai/nation)

---

Built with ❤️ by [Sarin Na Wangkanai](https://github.com/wangkanai) and [contributors](https://github.com/wangkanai/nation/graphs/contributors).