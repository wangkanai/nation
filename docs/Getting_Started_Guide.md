# Getting Started Guide

## Installation

### NuGet Package

Install the Wangkanai.Nation package via NuGet Package Manager:

```bash
dotnet add package Wangkanai.Nation
```

Or via Package Manager Console in Visual Studio:

```powershell
Install-Package Wangkanai.Nation
```

### Requirements

- **.NET 9.0** or later
- **Entity Framework Core 9.0** or later (for database integration)

## Quick Start

### 1. Basic Entity Usage

Start with creating geographical entities using the domain models:

```csharp
using Wangkanai.Nation.Models;
using Wangkanai.Nation.Urbans;

// Create a country
var thailand = new Country(
    id: 764,
    iso: "TH",
    code: 66,
    name: "Thailand", 
    native: "ไทย",
    population: 71_652_176
);

// Create a division (province)
var bangkok = new Province(
    id: 1,
    countryId: 764,
    iso: "TH-10",
    name: "Bangkok",
    native: "กรุงเทพมหานคร", 
    population: 5_692_284
);

// Create an urban area
var district = new City
{
    Id = 1,
    DivisionId = 1,
    Name = "Watthana",
    Native = "วัฒนา",
    Iso = "TH-10110"
};

// Check entity state
Console.WriteLine($"Thailand is transient: {thailand.IsTransient()}"); // False
Console.WriteLine($"District is transient: {district.IsTransient()}");  // False
```

### 2. Working with Seed Data

Use pre-built seed datasets for rapid development:

```csharp
using Wangkanai.Nation.Seeds;
using Wangkanai.Nation.Seeds.Thailand;

// Get all available countries
var countries = CountrySeed.Dataset;
foreach (var country in countries)
{
    Console.WriteLine($"{country.Name} ({country.Iso}) - Population: {country.Population:N0}");
}

// Get Thai provinces
var provinces = ProvinceSeed.Dataset;
foreach (var province in provinces)
{
    Console.WriteLine($"{province.Name} ({province.Native}) - Population: {province.Population:N0}");
}
```

### 3. Entity Framework Integration

Configure your DbContext to work with Nation entities:

```csharp
using Microsoft.EntityFrameworkCore;
using Wangkanai.Nation.Models;
using Wangkanai.Nation.Urbans;
using Wangkanai.Nation.Configurations;

public class ApplicationDbContext : DbContext
{
    public DbSet<Country> Countries { get; set; }
    public DbSet<Division> Divisions { get; set; }
    public DbSet<Urban> Urbans { get; set; }

    // Specific division types (optional)
    public DbSet<Province> Provinces { get; set; }
    public DbSet<State> States { get; set; }
    public DbSet<Region> Regions { get; set; }

    // Specific urban types (optional)  
    public DbSet<City> Cities { get; set; }
    public DbSet<Town> Towns { get; set; }

    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options) { }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Apply Nation configurations
        modelBuilder.ApplyConfiguration(new CountryConfiguration());
        modelBuilder.ApplyConfiguration(new DivisionConfiguration());
        modelBuilder.ApplyConfiguration(new UrbanConfiguration());

        base.OnModelCreating(modelBuilder);
    }
}
```

### 4. Database Setup

Configure your database connection and create initial migration:

```csharp
// Startup.cs or Program.cs
services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(connectionString));

// Or for development with SQLite
services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlite(connectionString));
```

Create and run migrations:

```bash
# Create initial migration
dotnet ef migrations add InitialCreate

# Update database
dotnet ef database update
```

## Common Usage Patterns

### Creating a Complete Geographical Hierarchy

```csharp
public async Task CreateGeographicalHierarchy(ApplicationDbContext context)
{
    // 1. Create or get country
    var country = new Country(840, "US", 1, "United States", "United States", 331_900_000);
    context.Countries.Add(country);
    await context.SaveChangesAsync();

    // 2. Create divisions (states)
    var california = new State(1, 840, "US-CA", "California", "California", 39_538_223);
    var texas = new State(2, 840, "US-TX", "Texas", "Texas", 29_145_505);
    
    context.Divisions.AddRange(california, texas);
    await context.SaveChangesAsync();

    // 3. Create urban areas
    var losAngeles = new City 
    { 
        DivisionId = 1, // California
        Name = "Los Angeles", 
        Native = "Los Angeles", 
        Iso = "US-CA-LA" 
    };
    
    var houston = new City 
    { 
        DivisionId = 2, // Texas
        Name = "Houston", 
        Native = "Houston", 
        Iso = "US-TX-HOU" 
    };

    context.Urbans.AddRange(losAngeles, houston);
    await context.SaveChangesAsync();
}
```

### Querying Geographical Data

```csharp
public async Task QueryExamples(ApplicationDbContext context)
{
    // Get all countries
    var countries = await context.Countries.ToListAsync();

    // Get specific division types
    var states = await context.Divisions.OfType<State>().ToListAsync();
    var provinces = await context.Divisions.OfType<Province>().ToListAsync();

    // Get cities in a specific division
    var citiesInCalifornia = await context.Urbans.OfType<City>()
        .Where(c => c.DivisionId == 1) // California ID
        .ToListAsync();

    // Get country with all its divisions
    var countryWithDivisions = await context.Countries
        .Include("Divisions") // Note: Navigation property needs to be configured
        .FirstOrDefaultAsync(c => c.Iso == "US");

    // Search by name
    var searchResults = await context.Countries
        .Where(c => c.Name.Contains("United") || c.Native.Contains("United"))
        .ToListAsync();
}
```

### Seeding Database on Startup

```csharp
public class DatabaseSeeder
{
    private readonly ApplicationDbContext _context;

    public DatabaseSeeder(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task SeedAsync()
    {
        // Seed countries if none exist
        if (!await _context.Countries.AnyAsync())
        {
            foreach (var country in CountrySeed.Dataset)
            {
                _context.Countries.Add(country);
            }
            await _context.SaveChangesAsync();
        }

        // Seed Thai provinces if none exist
        if (!await _context.Divisions.OfType<Province>().AnyAsync())
        {
            foreach (var province in ProvinceSeed.Dataset)
            {
                _context.Divisions.Add(province);
            }
            await _context.SaveChangesAsync();
        }
    }
}

// In Startup.cs or Program.cs
public async Task Main(string[] args)
{
    var host = CreateHostBuilder(args).Build();
    
    using (var scope = host.Services.CreateScope())
    {
        var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        var seeder = new DatabaseSeeder(context);
        await seeder.SeedAsync();
    }
    
    await host.RunAsync();
}
```

## Entity Type Overview

### Countries

Countries represent sovereign nations and are the root of the geographical hierarchy:

```csharp
var country = new Country(
    id: 764,           // Unique identifier
    iso: "TH",         // ISO 3166-1 alpha-2 code
    code: 66,          // International dialing code
    name: "Thailand",  // English name
    native: "ไทย",     // Native language name  
    population: 71_652_176  // Population count
);
```

### Administrative Divisions

Divisions represent administrative subdivisions within countries. Choose the appropriate type based on the country's administrative system:

```csharp
// United States (States)
var california = new State(1, 840, "US-CA", "California", "California", 39_538_223);

// Thailand (Provinces)  
var bangkok = new Province(2, 764, "TH-10", "Bangkok", "กรุงเทพมหานคร", 5_692_284);

// France (Regions)
var ilesDeFrance = new Region(3, 250, "FR-11", "Île-de-France", "Île-de-France", 12_278_210);

// Switzerland (Cantons)
var zurich = new Canton(4, 756, "CH-ZH", "Zürich", "Zürich", 1_539_275);
```

### Urban Areas

Urban areas represent populated settlements within administrative divisions:

```csharp
// Major city
var newYork = new City 
{ 
    DivisionId = 36, // New York State ID
    Name = "New York City", 
    Native = "New York City", 
    Iso = "US-NY-NYC" 
};

// Small town
var smallTown = new Town 
{ 
    DivisionId = 36, 
    Name = "Albany", 
    Native = "Albany", 
    Iso = "US-NY-ALB" 
};

// Rural village
var village = new Village 
{ 
    DivisionId = 36, 
    Name = "Cooperstown", 
    Native = "Cooperstown", 
    Iso = "US-NY-COP" 
};
```

## Configuration Options

### Entity Framework Options

```csharp
protected override void OnModelCreating(ModelBuilder modelBuilder)
{
    // Apply all Nation configurations
    modelBuilder.ApplyConfigurationsFromAssembly(typeof(CountryConfiguration).Assembly);

    // Or apply individually
    modelBuilder.ApplyConfiguration(new CountryConfiguration());
    modelBuilder.ApplyConfiguration(new DivisionConfiguration()); 
    modelBuilder.ApplyConfiguration(new UrbanConfiguration());

    // Add custom configurations
    modelBuilder.Entity<Country>()
        .HasIndex(c => c.Iso)
        .IsUnique();

    modelBuilder.Entity<Division>()
        .HasIndex(d => new { d.CountryId, d.Iso })
        .IsUnique();
}
```

### Custom Validation

```csharp
public class CountryValidator
{
    public static bool IsValidIsoCode(string iso)
    {
        return !string.IsNullOrEmpty(iso) && iso.Length == 2 && iso.All(char.IsLetter);
    }

    public static bool IsValidPopulation(int population)
    {
        return population >= 0;
    }
}

// Usage in entity creation
var country = new Country(764, "TH", 66, "Thailand", "ไทย", 71_652_176);
if (!CountryValidator.IsValidIsoCode(country.Iso))
{
    throw new ArgumentException("Invalid ISO code");
}
```

## Migration from Other Systems

### From Custom Country Data

```csharp
public class CountryMigration
{
    public async Task MigrateFromCsv(string csvPath, ApplicationDbContext context)
    {
        var lines = await File.ReadAllLinesAsync(csvPath);
        
        foreach (var line in lines.Skip(1)) // Skip header
        {
            var parts = line.Split(',');
            var country = new Country(
                id: int.Parse(parts[0]),
                iso: parts[1],
                code: int.Parse(parts[2]),
                name: parts[3],
                native: parts[4],
                population: int.Parse(parts[5])
            );
            
            context.Countries.Add(country);
        }
        
        await context.SaveChangesAsync();
    }
}
```

### From Existing Database Schema

```csharp
public class LegacyDataMigration
{
    public async Task MigrateFromLegacySchema(ApplicationDbContext legacyContext, ApplicationDbContext nationContext)
    {
        // Migrate countries
        var legacyCountries = await legacyContext.LegacyCountries.ToListAsync();
        foreach (var legacy in legacyCountries)
        {
            var country = new Country(
                legacy.CountryId,
                legacy.CountryCode,
                legacy.PhoneCode,
                legacy.EnglishName,
                legacy.LocalName ?? legacy.EnglishName,
                legacy.PopulationCount
            );
            nationContext.Countries.Add(country);
        }

        await nationContext.SaveChangesAsync();
    }
}
```

## Best Practices

### 1. Entity Creation

- **Use constructors**: Leverage parameterized constructors for required fields
- **Validate input**: Ensure ISO codes and names meet requirements
- **Set relationships**: Always establish parent-child relationships correctly

```csharp
// Good: Using constructor with all required parameters
var country = new Country(764, "TH", 66, "Thailand", "ไทย", 71_652_176);

// Avoid: Parameterless constructor with property setting (more error-prone)
var country = new Country 
{
    Id = 764,
    Iso = "TH",
    Code = 66,
    Name = "Thailand",
    Native = "ไทย", 
    Population = 71_652_176
};
```

### 2. Querying Performance

- **Use specific types**: Use `OfType<T>()` for better performance
- **Include strategy**: Consider your loading strategy for related data
- **Filter early**: Apply filters early in LINQ chains

```csharp
// Good: Type-specific query
var states = await context.Divisions.OfType<State>()
    .Where(s => s.Population > 1_000_000)
    .ToListAsync();

// Good: Early filtering
var largeCities = await context.Urbans.OfType<City>()
    .Where(c => c.Name.StartsWith("New"))
    .OrderBy(c => c.Name)
    .ToListAsync();
```

### 3. Data Integrity

- **Foreign keys**: Ensure parent entities exist before creating children
- **Unique constraints**: Implement business key uniqueness
- **Cascading**: Configure appropriate cascade behaviors

```csharp
// Good: Check parent exists
var country = await context.Countries.FindAsync(countryId);
if (country != null)
{
    var division = new Province(1, countryId, "XX-01", "Province Name", "Native Name", 100000);
    context.Divisions.Add(division);
}
```

## Next Steps

- [Advanced Usage](Advanced_Usage.md) - EF Core integration patterns and seed data usage
- [API Reference](API_Reference.md) - Complete API documentation  
- [Project Architecture](Project_Architecture_Overview.md) - Understanding the internal structure
- [Domain Model Structure](Domain_Model_Structure.md) - Deep dive into the domain design