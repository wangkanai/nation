# Domain Model Structure

## Overview

The Nation library implements a comprehensive domain model following Domain-Driven Design (DDD) principles. The architecture provides a hierarchical structure for geographical data with three main levels: Countries, Divisions, and Urban areas.

## Architecture Diagram

```
                    IEntity<T>
                        ↑
                   Entity<T>
                   ↗    ↑    ↖
            Country  Division  Urban
                       ↑        ↑
              [25+ Division  [7+ Urban
                Types]      Types]
```

## Core Domain Foundation

### Entity Hierarchy

The foundation of the domain model is built on a generic entity pattern:

```csharp
// Base interface for all entities
IEntity<T> where T : IComparable<T>, IEquatable<T>
├── Id: T
└── IsTransient(): bool

// Abstract base implementation  
Entity<T> : IEntity<T>
├── Equality operations (==, !=, Equals)
├── Hash code generation
└── Transient state detection
```

### Key Design Principles

1. **Generic Identity**: All entities use typed identifiers (currently `int`)
2. **Transient Detection**: Entities can determine if they're persisted or new
3. **Value Equality**: Entities are equal if they have the same ID and type
4. **EF Core Proxy Support**: Handles Entity Framework dynamic proxies correctly

## Geographical Hierarchy

### Three-Tier Structure

```
Country (Root Aggregate)
    ├── CountryId: int (Primary Key)
    ├── ISO: string (2 chars) - ISO 3166-1 alpha-2
    ├── Code: int - International dialing code  
    ├── Name: string (100 chars) - English name
    ├── Native: string (100 chars) - Native language name
    └── Population: int
    
Division (Administrative Subdivision)
    ├── Id: int (Primary Key)
    ├── CountryId: int (Foreign Key → Country.Id)
    ├── ISO: string (2 chars) - ISO 3166-2 subdivision code
    ├── Name: string (100 chars) - English name
    ├── Native: string (100 chars) - Native language name
    └── Population: int
    
Urban (Urban Area/Settlement)
    ├── Id: int (Primary Key)  
    ├── DivisionId: int (Foreign Key → Division.Id)
    ├── Name: string (100 chars) - English name
    ├── Native: string (100 chars) - Native language name
    └── ISO: string (5 chars) - Extended ISO code
```

## Entity Relationships

### Primary Relationships

```csharp
// One-to-Many: Country → Divisions
Country (1) ←→ (Many) Division
    // Navigation: Country.Id = Division.CountryId

// One-to-Many: Division → Urban Areas  
Division (1) ←→ (Many) Urban
    // Navigation: Division.Id = Urban.DivisionId
```

### Foreign Key Constraints

| Child Entity | Foreign Key | Parent Entity | Relationship |
|--------------|-------------|---------------|--------------|
| Division | CountryId | Country.Id | Required |
| Urban | DivisionId | Division.Id | Required |

## Administrative Division Types

### Classification System

The library supports a comprehensive classification of administrative divisions worldwide through inheritance:

#### Tier 1: Primary Administrative Divisions

| Type | Usage | Examples |
|------|-------|----------|
| `Province` | Provincial systems | Canada, Thailand, China, Argentina |
| `State` | Federal/state systems | USA, Australia, Germany, India |
| `Region` | Regional systems | France, Italy, Spain, Chile |
| `County` | County systems | UK, Ireland, USA (local level) |
| `Canton` | Cantonal systems | Switzerland |
| `District` | District systems | India, Bangladesh, Nepal |

#### Tier 2: Secondary Administrative Divisions

| Type | Description |
|------|-------------|
| `Municipality` | Municipal administrative areas |
| `Territory` | Territorial divisions (Australia, Canada) |
| `Prefecture` | Prefectural systems (Japan, Greece) |
| `Department` | Departmental divisions (France, Colombia) |
| `Area` | General administrative areas |
| `Community` | Community-level divisions |
| `Parish` | Parish systems (Louisiana, UK) |

#### Tier 3: Specialized Administrative Divisions

| Type | Geographical Context |
|------|---------------------|
| `Oblast` | Russia, Ukraine, Eastern Europe |
| `Voivodeship` | Poland |
| `Banner` | Mongolia (Inner Mongolia) |
| `Barangay` | Philippines (smallest admin unit) |
| `Kampong` | Malaysia, Brunei |
| `Barony` | Historical (Ireland, Scotland) |
| `Hundred` | Historical (England) |
| `Kingdom` | Sub-national kingdoms |
| `Principality` | Principalities within larger states |
| `Regency` | Indonesia |
| `Republic` | Autonomous republics within federations |
| `Riding` | Historical (Yorkshire, Canada) |
| `Theme` | Historical (Byzantine Empire) |
| `Banat` | Historical region type |

## Urban Area Classification

### Urban Hierarchy

```csharp
Urban (Abstract Base)
├── Major Urban Centers
│   ├── City - Large urban areas, major population centers
│   └── Town - Medium-sized urban settlements
├── Administrative Areas  
│   ├── Ward - Administrative districts within cities
│   ├── Shire - Administrative/geographical areas
│   └── Amphor - Thai-specific administrative districts
└── Rural/Small Settlements
    ├── Village - Rural communities
    └── Hamlet - Very small rural settlements
```

### Urban Classification Criteria

| Type | Typical Population | Administrative Level | Usage |
|------|-------------------|---------------------|--------|
| City | 50,000+ | Primary urban center | Major metropolitan areas |
| Town | 1,000-50,000 | Secondary urban center | Regional centers |
| Ward | Variable | Sub-city division | Administrative districts |
| Village | 100-5,000 | Rural community | Rural settlements |
| Hamlet | <500 | Small settlement | Very small communities |

## Inheritance Strategy

### Table Per Hierarchy (TPH)

The library uses Entity Framework's Table Per Hierarchy strategy for both Division and Urban hierarchies:

```csharp
// Division TPH Configuration
builder.HasDiscriminator<string>("type")
    .HasValue<Province>("Province")
    .HasValue<State>("State")
    .HasValue<Region>("Region")
    // ... all other division types
```

### Benefits

1. **Performance**: Single table queries for all division types
2. **Simplicity**: No complex joins between related types
3. **Flexibility**: Easy to add new administrative division types
4. **Query Efficiency**: Can query all divisions or filter by specific types

### Trade-offs

1. **Null Columns**: Some columns may be null for certain types
2. **Table Size**: Single large table instead of multiple smaller ones
3. **Schema Evolution**: Changes affect entire hierarchy

## Domain Invariants

### Business Rules

1. **Unique Identifiers**: Each entity must have a unique ID within its type
2. **Required References**: Divisions must belong to a Country; Urbans must belong to a Division
3. **ISO Code Uniqueness**: ISO codes should be unique within their scope
4. **Name Requirements**: Both English and native names are required
5. **Population Constraints**: Population must be non-negative

### Validation Rules

```csharp
// Country Invariants
- ISO code: exactly 2 characters
- International code: positive integer
- Names: 1-100 characters
- Population: >= 0

// Division Invariants  
- CountryId: must reference existing Country
- ISO code: exactly 2 characters (subdivision format)
- Names: 1-100 characters
- Population: >= 0

// Urban Invariants
- DivisionId: must reference existing Division
- ISO code: 1-5 characters (extended format)
- Names: 1-100 characters
```

## Entity Framework Configuration

### Database Schema

```sql
-- Countries Table
Countries (
    Id int PRIMARY KEY,
    Iso nvarchar(2) NOT NULL,
    Code int NOT NULL,
    Name nvarchar(100) NOT NULL,
    Native nvarchar(100) NOT NULL,
    Population int
)

-- Divisions Table (TPH with discriminator)
Divisions (
    Id int PRIMARY KEY,
    CountryId int NOT NULL FOREIGN KEY REFERENCES Countries(Id),
    Iso nvarchar(2) NOT NULL,
    Name nvarchar(100) NOT NULL, 
    Native nvarchar(100) NOT NULL,
    Population int,
    type nvarchar(max) NOT NULL -- Discriminator column
)

-- Urbans Table (TPH with discriminator)  
Urbans (
    Id int PRIMARY KEY,
    DivisionId int NOT NULL FOREIGN KEY REFERENCES Divisions(Id),
    Name nvarchar(100) NOT NULL,
    Native nvarchar(100) NOT NULL,
    Iso nvarchar(5) NOT NULL,
    type nvarchar(max) NOT NULL -- Discriminator column
)

-- Indexes
CREATE INDEX IX_Divisions_CountryId ON Divisions(CountryId)
CREATE INDEX IX_Urbans_DivisionId ON Urbans(DivisionId)
CREATE INDEX IX_Urbans_Iso ON Urbans(Iso)
```

### Configuration Classes

Each entity type has a dedicated configuration class:

- `CountryConfiguration`: Configures Country entity and seeds initial data
- `DivisionConfiguration`: Configures Division hierarchy with TPH discrimination
- `UrbanConfiguration`: Configures Urban hierarchy with indexes and constraints

## Extension Points

### Adding New Division Types

1. Create new class inheriting from `Division`:
```csharp
public class NewDivisionType : Division 
{
    // Additional properties if needed
}
```

2. Entity Framework automatically includes it in TPH mapping

### Adding New Urban Types

1. Create new class inheriting from `Urban`:
```csharp
public class NewUrbanType : Urban
{
    // Additional properties if needed  
}
```

2. No additional configuration required

### Custom Properties

For specialized administrative divisions requiring additional properties:

```csharp
public class Prefecture : Division
{
    public string PrefecturalCode { get; set; }
    public DateTime EstablishedDate { get; set; }
}
```

## Performance Considerations

### Query Patterns

```csharp
// Efficient: Single table query
var states = context.Divisions.OfType<State>().ToList();

// Efficient: Include related data
var countriesWithDivisions = context.Countries
    .Include(c => c.Divisions)
    .ToList();

// Efficient: Filtered queries
var largeCities = context.Urbans.OfType<City>()
    .Where(c => c.Population > 1_000_000)
    .ToList();
```

### Index Strategy

1. **Primary Keys**: Clustered indexes on Id columns
2. **Foreign Keys**: Non-clustered indexes for join performance
3. **ISO Codes**: Indexes for lookup scenarios
4. **Discriminators**: Implicit indexes for TPH filtering

## Migration Strategy

### Schema Evolution

```csharp
// Adding new administrative division type
public class AddNewDivisionType : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        // TPH automatically supports new types
        // No schema changes required
    }
}

// Adding properties to existing types
public class AddPrefectureProperties : Migration  
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.AddColumn<string>(
            name: "PrefecturalCode",
            table: "Divisions", 
            nullable: true);
    }
}
```

## Best Practices

### Entity Creation

1. **Use Constructors**: Leverage parameterized constructors for required properties
2. **Validate Input**: Ensure ISO codes and names meet requirements
3. **Set Relationships**: Always establish parent-child relationships correctly

### Querying

1. **Specific Types**: Use `OfType<T>()` for type-specific queries
2. **Lazy Loading**: Consider loading strategies for related data
3. **Filtering**: Apply filters early in LINQ chains

### Data Integrity

1. **Foreign Keys**: Ensure parent entities exist before creating children
2. **Unique Constraints**: Implement unique constraints on business keys
3. **Cascading**: Configure appropriate cascade delete behaviors