# API Reference

## Table of Contents

- [Core Domain](#core-domain)
  - [IEntity&lt;T&gt;](#ientityt)
  - [Entity&lt;T&gt;](#entityt)
- [Country Model](#country-model)
  - [Country](#country)
  - [CountryConfiguration](#countryconfiguration)
  - [CountrySeed](#countryseed)
- [Division Models](#division-models)
  - [Division (Abstract)](#division-abstract)
  - [Administrative Division Types](#administrative-division-types)
  - [DivisionConfiguration](#divisionconfiguration)
- [Urban Models](#urban-models)
  - [Urban (Abstract)](#urban-abstract)
  - [Urban Area Types](#urban-area-types)
  - [UrbanConfiguration](#urbanconfiguration)
- [Seed Data](#seed-data)

---

## Core Domain

### IEntity&lt;T&gt;

**Namespace:** `Wangkanai.Domain`

Generic entity interface that defines a unique identifier and transient state detection.

#### Type Parameters
- `T` - The type of the unique identifier. Must implement `IComparable<T>` and `IEquatable<T>`

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `Id` | `T` | Gets or sets the unique identifier for the entity |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `IsTransient()` | `bool` | Returns true if the entity is transient (not yet persisted) |

#### Example

```csharp
using Wangkanai.Domain;

public class CustomEntity : IEntity<int>
{
    public int Id { get; set; }
    
    public bool IsTransient() => Id == 0;
}
```

---

### Entity&lt;T&gt;

**Namespace:** `Wangkanai.Domain`

Abstract base class providing entity functionality with unique identifier support, equality operations, and transient state detection.

#### Type Parameters
- `T` - The type of the unique identifier. Must implement `IComparable<T>` and `IEquatable<T>`

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `Id` | `T` | Gets or sets the unique identifier for the entity |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `IsTransient()` | `bool` | Returns true if the entity ID equals the default value for type T |
| `GetHashCode()` | `int` | Returns hash code based on ID (or base hash code if transient) |
| `Equals(object?)` | `bool` | Compares entities based on ID and type |

#### Operators

| Operator | Description |
|----------|-------------|
| `==` | Equality comparison based on ID |
| `!=` | Inequality comparison based on ID |

#### Example

```csharp
using Wangkanai.Domain;

public class Product : Entity<int>
{
    public string Name { get; set; }
    public decimal Price { get; set; }
}

var product1 = new Product { Id = 1, Name = "Laptop" };
var product2 = new Product { Id = 1, Name = "Laptop" };
var isEqual = product1 == product2; // true - same ID
```

---

## Country Model

### Country

**Namespace:** `Wangkanai.Nation.Models`  
**Inherits:** `Entity<int>`

Represents a country with ISO codes, population, and localized names.

#### Constructors

```csharp
// Default constructor
public Country()

// Full constructor
public Country(int id, string iso, int code, string name, string native, int population = 0)
```

#### Properties

| Property | Type | Description | Max Length |
|----------|------|-------------|------------|
| `Id` | `int` | Unique country identifier (inherited) | - |
| `Iso` | `string` | ISO 3166-1 alpha-2 code | 2 |
| `Code` | `int` | International telephone country code | - |
| `Name` | `string` | English country name | 100 |
| `Native` | `string` | Native language country name | 100 |
| `Population` | `int` | Country population | - |

#### Example

```csharp
using Wangkanai.Nation.Models;

// Create a country
var thailand = new Country(
    id: 764,
    iso: "TH", 
    code: 66,
    name: "Thailand",
    native: "ไทย",
    population: 71_652_176
);

// Check if transient
var isNew = thailand.IsTransient(); // false - has ID
```

---

### CountryConfiguration

**Namespace:** `Wangkanai.Nation.Configurations`  
**Implements:** `IEntityTypeConfiguration<Country>`

Entity Framework configuration for Country entity.

#### Configuration Details

```csharp
public void Configure(EntityTypeBuilder<Country> builder)
{
    // ISO code: required, max 2 characters
    builder.Property(x => x.Iso)
           .HasMaxLength(2)
           .IsRequired();

    // English name: required, max 100 characters  
    builder.Property(x => x.Name)
           .HasMaxLength(100)
           .IsRequired();

    // Native name: required, max 100 characters, Unicode support
    builder.Property(x => x.Native)
           .HasMaxLength(100)
           .IsUnicode()
           .IsRequired();

    // Seed data from CountrySeed.Dataset
    builder.HasData(CountrySeed.Dataset);
}
```

#### Usage with DbContext

```csharp
using Microsoft.EntityFrameworkCore;
using Wangkanai.Nation.Models;
using Wangkanai.Nation.Configurations;

public class ApplicationDbContext : DbContext
{
    public DbSet<Country> Countries { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfiguration(new CountryConfiguration());
    }
}
```

---

### CountrySeed

**Namespace:** `Wangkanai.Nation.Seeds`

Provides seed data for countries.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `Dataset` | `List<Country>` | Static list of pre-configured country data |

#### Available Data

Currently includes:
- **Thailand** - ID: 66, ISO: "TH", Code: 66, Name: "Thailand", Native: "ไทย", Population: 71,652,176

#### Example

```csharp
using Wangkanai.Nation.Seeds;

// Get all available countries
var countries = CountrySeed.Dataset;

// Seed database
foreach (var country in countries)
{
    context.Countries.Add(country);
}
await context.SaveChangesAsync();
```

---

## Division Models

### Division (Abstract)

**Namespace:** `Wangkanai.Nation.Models`  
**Inherits:** `Entity<int>`

Abstract base class for administrative divisions (provinces, states, regions, etc.).

#### Constructors

```csharp
// Default constructor
public Division()

// Full constructor
public Division(int id, int countryId, string iso, string name, string native, int population = 0)
```

#### Properties

| Property | Type | Description | Max Length |
|----------|------|-------------|------------|
| `Id` | `int` | Unique division identifier (inherited) | - |
| `CountryId` | `int` | Foreign key to parent country | - |
| `Iso` | `string` | ISO subdivision code | 2 |
| `Name` | `string` | English division name | 100 |
| `Native` | `string` | Native language division name | 100 |
| `Population` | `int` | Division population | - |

#### Example

```csharp
using Wangkanai.Nation.Models;

// Create a division (using Province as example)
var bangkok = new Province(
    id: 1,
    countryId: 764, // Thailand
    iso: "TH-10",
    name: "Bangkok",
    native: "กรุงเทพมหานคร",
    population: 5_692_284
);
```

---

### Administrative Division Types

All division types inherit from the `Division` base class and provide specialized implementations for different administrative levels worldwide.

#### Primary Administrative Divisions

| Class | Namespace | Description | Common Usage |
|-------|-----------|-------------|--------------|
| `Province` | `Wangkanai.Nation.Models` | Provincial divisions | Canada, Thailand, China |
| `State` | `Wangkanai.Nation.Models` | State divisions | US, Australia, Germany |
| `Region` | `Wangkanai.Nation.Models` | Regional divisions | France, Italy, Spain |
| `County` | `Wangkanai.Nation.Models` | County divisions | UK, Ireland, US |
| `Canton` | `Wangkanai.Nation.Models` | Cantonal divisions | Switzerland |
| `District` | `Wangkanai.Nation.Models` | District divisions | India, Bangladesh |

#### Secondary Administrative Divisions

| Class | Namespace | Description |
|-------|-----------|-------------|
| `Municipality` | `Wangkanai.Nation.Models` | Municipal divisions |
| `Territory` | `Wangkanai.Nation.Models` | Territorial divisions |
| `Prefecture` | `Wangkanai.Nation.Models` | Prefectural divisions |
| `Department` | `Wangkanai.Nation.Models` | Departmental divisions |
| `Area` | `Wangkanai.Nation.Models` | Area divisions |
| `Community` | `Wangkanai.Nation.Models` | Community divisions |
| `Parish` | `Wangkanai.Nation.Models` | Parish divisions |

#### Specialized Administrative Divisions

| Class | Namespace | Description |
|-------|-----------|-------------|
| `Barony` | `Wangkanai.Nation.Models` | Historical baronial divisions |
| `Banat` | `Wangkanai.Nation.Models` | Banat regional divisions |
| `Hundred` | `Wangkanai.Nation.Models` | Historical hundred divisions |
| `Kampong` | `Wangkanai.Nation.Models` | Kampong divisions (Malaysia/Brunei) |
| `Kingdom` | `Wangkanai.Nation.Models` | Kingdom divisions |
| `Principality` | `Wangkanai.Nation.Models` | Principality divisions |
| `Oblast` | `Wangkanai.Nation.Models` | Oblast divisions (Russia/Eastern Europe) |
| `Regency` | `Wangkanai.Nation.Models` | Regency divisions |
| `Republic` | `Wangkanai.Nation.Models` | Republic divisions |
| `Riding` | `Wangkanai.Nation.Models` | Riding divisions |
| `Theme` | `Wangkanai.Nation.Models` | Theme divisions |
| `Voivodeship` | `Wangkanai.Nation.Models` | Voivodeship divisions (Poland) |
| `Banner` | `Wangkanai.Nation.Models` | Banner divisions (Mongolia) |
| `Barangay` | `Wangkanai.Nation.Models` | Barangay divisions (Philippines) |

#### Example Usage

```csharp
using Wangkanai.Nation.Models;

// Different administrative division types
var usState = new State(1, 840, "US-CA", "California", "California", 39_538_223);
var frenchRegion = new Region(2, 250, "FR-75", "Île-de-France", "Île-de-France", 12_278_210);
var swissCanton = new Canton(3, 756, "CH-ZH", "Zürich", "Zürich", 1_539_275);
var ukCounty = new County(4, 826, "GB-ENG", "Yorkshire", "Yorkshire", 5_400_000);
```

---

### DivisionConfiguration

**Namespace:** `Wangkanai.Nation.Models`  
**Implements:** `IEntityTypeConfiguration<Division>`

Entity Framework configuration for Division hierarchy using Table Per Hierarchy (TPH) inheritance.

#### Configuration Details

```csharp
public void Configure(EntityTypeBuilder<Division> builder)
{
    // ISO code: required, max 2 characters
    builder.Property(x => x.Iso)
           .HasMaxLength(2)
           .IsRequired();

    // English name: required, max 100 characters
    builder.Property(x => x.Name)
           .HasMaxLength(100)
           .IsRequired();

    // Native name: required, max 100 characters, Unicode support
    builder.Property(x => x.Native)
           .HasMaxLength(100)
           .IsUnicode()
           .IsRequired();

    // Configure TPH inheritance with discriminator
    builder.HasDiscriminator<string>("type");
}
```

#### Usage

```csharp
public class ApplicationDbContext : DbContext
{
    public DbSet<Division> Divisions { get; set; }
    public DbSet<Province> Provinces { get; set; }
    public DbSet<State> States { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfiguration(new DivisionConfiguration());
    }
}
```

---

## Urban Models

### Urban (Abstract)

**Namespace:** `Wangkanai.Nation.Urbans`  
**Inherits:** `Entity<int>`

Abstract base class for urban areas (cities, towns, villages, etc.).

#### Properties

| Property | Type | Description | Max Length | Index |
|----------|------|-------------|------------|-------|
| `Id` | `int` | Unique urban area identifier (inherited) | - | Primary Key |
| `DivisionId` | `int` | Foreign key to parent division | - | Yes |
| `Name` | `string` | English urban area name | 100 | - |
| `Native` | `string` | Native language urban area name | 100 | - |
| `Iso` | `string` | ISO urban area code | 5 | Yes |

#### Example

```csharp
using Wangkanai.Nation.Urbans;

// Create an urban area (using City as example)
var bangkok = new City 
{
    Id = 1,
    DivisionId = 1, // Bangkok Province
    Name = "Bangkok",
    Native = "กรุงเทพมหานคร",
    Iso = "TH-10"
};
```

---

### Urban Area Types

All urban types inherit from the `Urban` base class, providing specialized implementations for different types of populated areas.

#### Major Urban Areas

| Class | Namespace | Description |
|-------|-----------|-------------|
| `City` | `Wangkanai.Nation.Urbans` | Major urban centers |
| `Town` | `Wangkanai.Nation.Urbans` | Smaller urban areas |

#### Administrative Urban Areas

| Class | Namespace | Description |
|-------|-----------|-------------|
| `Ward` | `Wangkanai.Nation.Urbans` | Administrative wards |
| `Shire` | `Wangkanai.Nation.Urbans` | Shire areas |
| `Amphor` | `Wangkanai.Nation.Urbans` | Thai district areas |

#### Rural/Small Urban Areas

| Class | Namespace | Description |
|-------|-----------|-------------|
| `Village` | `Wangkanai.Nation.Urbans` | Rural villages |
| `Hamlet` | `Wangkanai.Nation.Urbans` | Small rural settlements |

#### Example Usage

```csharp
using Wangkanai.Nation.Urbans;

// Different urban area types
var majorCity = new City 
{ 
    Id = 1, 
    DivisionId = 1, 
    Name = "Bangkok", 
    Native = "กรุงเทพมหานคร", 
    Iso = "TH-10" 
};

var smallTown = new Town 
{ 
    Id = 2, 
    DivisionId = 1, 
    Name = "Ayutthaya", 
    Native = "อยุธยา", 
    Iso = "TH-14" 
};

var ruralVillage = new Village 
{ 
    Id = 3, 
    DivisionId = 2, 
    Name = "Ban Chang", 
    Native = "บ้านช้าง", 
    Iso = "TH-20" 
};
```

---

### UrbanConfiguration

**Namespace:** `Wangkanai.Nation.Urbans`  
**Implements:** `IEntityTypeConfiguration<Urban>`

Entity Framework configuration for Urban hierarchy.

#### Configuration Details

```csharp
public void Configure(EntityTypeBuilder<Urban> builder)
{
    // Foreign key to Division with index
    builder.HasIndex(u => u.DivisionId);
    builder.Property(u => u.DivisionId)
           .IsRequired();

    // English name: required, max 100 characters
    builder.Property(u => u.Name)
           .HasMaxLength(100)
           .IsRequired();

    // Native name: required, max 100 characters, Unicode support
    builder.Property(u => u.Native)
           .HasMaxLength(100)
           .IsUnicode()
           .IsRequired();

    // ISO code: indexed, required, max 5 characters
    builder.HasIndex(u => u.Iso);
    builder.Property(u => u.Iso)
           .HasMaxLength(5)
           .IsRequired();
}
```

#### Usage

```csharp
public class ApplicationDbContext : DbContext
{
    public DbSet<Urban> Urbans { get; set; }
    public DbSet<City> Cities { get; set; }
    public DbSet<Town> Towns { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfiguration(new UrbanConfiguration());
    }
}
```

---

## Seed Data

### Thailand Province Seed

**Namespace:** `Wangkanai.Nation.Seeds.Thailand`

#### ProvinceSeed

Provides seed data for Thai provinces.

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `Dataset` | `List<Province>` | Static list of Thai province data |

##### Available Data

Currently includes:
- **Bangkok** - ID: 66_0001, Country: 66 (Thailand), ISO: "BKK", Name: "Bangkok", Native: "กรุงเทพมหานคร", Population: 5,692,284

##### Example

```csharp
using Wangkanai.Nation.Seeds.Thailand;

// Get all Thai provinces
var provinces = ProvinceSeed.Dataset;

// Seed database
foreach (var province in provinces)
{
    context.Divisions.Add(province);
}
await context.SaveChangesAsync();
```

---

## Complete Integration Example

```csharp
using Microsoft.EntityFrameworkCore;
using Wangkanai.Nation.Models;
using Wangkanai.Nation.Urbans;
using Wangkanai.Nation.Configurations;
using Wangkanai.Nation.Seeds;
using Wangkanai.Nation.Seeds.Thailand;

public class NationDbContext : DbContext
{
    // DbSets for all entity types
    public DbSet<Country> Countries { get; set; }
    public DbSet<Division> Divisions { get; set; }
    public DbSet<Province> Provinces { get; set; }
    public DbSet<State> States { get; set; }
    public DbSet<Urban> Urbans { get; set; }
    public DbSet<City> Cities { get; set; }
    public DbSet<Town> Towns { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Apply all configurations
        modelBuilder.ApplyConfiguration(new CountryConfiguration());
        modelBuilder.ApplyConfiguration(new DivisionConfiguration());
        modelBuilder.ApplyConfiguration(new UrbanConfiguration());
    }
}

// Usage example
public async Task SeedDatabaseAsync(NationDbContext context)
{
    // Seed countries
    foreach (var country in CountrySeed.Dataset)
    {
        context.Countries.Add(country);
    }

    // Seed Thai provinces
    foreach (var province in ProvinceSeed.Dataset)
    {
        context.Divisions.Add(province);
    }

    await context.SaveChangesAsync();
}
```