# Advanced Usage

## Entity Framework Core Integration Patterns

### DbContext Configuration

#### Complete DbContext Setup

```csharp
using Microsoft.EntityFrameworkCore;
using Wangkanai.Nation.Models;
using Wangkanai.Nation.Urbans;
using Wangkanai.Nation.Configurations;

public class NationDbContext : DbContext
{
    public NationDbContext(DbContextOptions<NationDbContext> options) 
        : base(options) { }

    // Core entity sets
    public DbSet<Country> Countries { get; set; } = null!;
    public DbSet<Division> Divisions { get; set; } = null!;
    public DbSet<Urban> Urbans { get; set; } = null!;

    // Specific division types for type-safe queries
    public DbSet<Province> Provinces { get; set; } = null!;
    public DbSet<State> States { get; set; } = null!;
    public DbSet<Region> Regions { get; set; } = null!;
    public DbSet<County> Counties { get; set; } = null!;
    public DbSet<Canton> Cantons { get; set; } = null!;
    public DbSet<District> Districts { get; set; } = null!;
    
    // Specific urban types
    public DbSet<City> Cities { get; set; } = null!;
    public DbSet<Town> Towns { get; set; } = null!;
    public DbSet<Village> Villages { get; set; } = null!;
    public DbSet<Ward> Wards { get; set; } = null!;

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Apply Nation entity configurations
        modelBuilder.ApplyConfiguration(new CountryConfiguration());
        modelBuilder.ApplyConfiguration(new DivisionConfiguration());
        modelBuilder.ApplyConfiguration(new UrbanConfiguration());

        // Add navigation properties
        ConfigureNavigationProperties(modelBuilder);
        
        // Add custom indexes and constraints
        ConfigureIndexesAndConstraints(modelBuilder);

        base.OnModelCreating(modelBuilder);
    }

    private void ConfigureNavigationProperties(ModelBuilder modelBuilder)
    {
        // Country -> Divisions relationship
        modelBuilder.Entity<Country>()
            .HasMany<Division>()
            .WithOne()
            .HasForeignKey(d => d.CountryId)
            .OnDelete(DeleteBehavior.Cascade);

        // Division -> Urbans relationship  
        modelBuilder.Entity<Division>()
            .HasMany<Urban>()
            .WithOne()
            .HasForeignKey(u => u.DivisionId)
            .OnDelete(DeleteBehavior.Cascade);
    }

    private void ConfigureIndexesAndConstraints(ModelBuilder modelBuilder)
    {
        // Unique constraints on ISO codes
        modelBuilder.Entity<Country>()
            .HasIndex(c => c.Iso)
            .IsUnique()
            .HasDatabaseName("IX_Countries_Iso_Unique");

        modelBuilder.Entity<Division>()
            .HasIndex(d => new { d.CountryId, d.Iso })
            .IsUnique()
            .HasDatabaseName("IX_Divisions_CountryId_Iso_Unique");

        // Performance indexes
        modelBuilder.Entity<Country>()
            .HasIndex(c => c.Name)
            .HasDatabaseName("IX_Countries_Name");

        modelBuilder.Entity<Division>()
            .HasIndex(d => d.Name)
            .HasDatabaseName("IX_Divisions_Name");

        modelBuilder.Entity<Urban>()
            .HasIndex(u => u.Name)
            .HasDatabaseName("IX_Urbans_Name");
    }
}
```

#### Dependency Injection Setup

```csharp
// ASP.NET Core Startup/Program.cs
public void ConfigureServices(IServiceCollection services)
{
    services.AddDbContext<NationDbContext>(options =>
    {
        options.UseSqlServer(connectionString, sqlOptions =>
        {
            sqlOptions.EnableRetryOnFailure(
                maxRetryCount: 3,
                maxRetryDelay: TimeSpan.FromSeconds(5),
                errorNumbersToAdd: null);
        });
        
        // Enable sensitive data logging in development
        if (environment.IsDevelopment())
        {
            options.EnableSensitiveDataLogging();
            options.LogTo(Console.WriteLine, LogLevel.Information);
        }
    });
}

// Alternative: SQLite for development/testing
services.AddDbContext<NationDbContext>(options =>
    options.UseSqlite($"Data Source={Path.Join(contentRoot, "nation.db")}"));
```

### Advanced Querying Patterns

#### Complex Geographical Queries

```csharp
public class GeographicalQueryService
{
    private readonly NationDbContext _context;

    public GeographicalQueryService(NationDbContext context)
    {
        _context = context;
    }

    // Get complete geographical hierarchy
    public async Task<CountryHierarchy> GetCountryHierarchyAsync(string countryIso)
    {
        var country = await _context.Countries
            .Where(c => c.Iso == countryIso)
            .Select(c => new CountryHierarchy
            {
                Country = c,
                Divisions = _context.Divisions
                    .Where(d => d.CountryId == c.Id)
                    .Select(d => new DivisionHierarchy
                    {
                        Division = d,
                        Urbans = _context.Urbans
                            .Where(u => u.DivisionId == d.Id)
                            .ToList()
                    })
                    .ToList()
            })
            .FirstOrDefaultAsync();

        return country;
    }

    // Population-based queries
    public async Task<List<Division>> GetMostPopulatedDivisionsAsync(int topCount = 10)
    {
        return await _context.Divisions
            .OrderByDescending(d => d.Population)
            .Take(topCount)
            .ToListAsync();
    }

    // Geographic search with fuzzy matching
    public async Task<SearchResults> SearchPlacesAsync(string searchTerm, int maxResults = 50)
    {
        var normalizedTerm = searchTerm.ToLower().Trim();
        
        var countries = await _context.Countries
            .Where(c => EF.Functions.Like(c.Name.ToLower(), $"%{normalizedTerm}%") ||
                       EF.Functions.Like(c.Native.ToLower(), $"%{normalizedTerm}%"))
            .Take(maxResults / 3)
            .ToListAsync();

        var divisions = await _context.Divisions
            .Where(d => EF.Functions.Like(d.Name.ToLower(), $"%{normalizedTerm}%") ||
                       EF.Functions.Like(d.Native.ToLower(), $"%{normalizedTerm}%"))
            .Take(maxResults / 3)
            .ToListAsync();

        var urbans = await _context.Urbans
            .Where(u => EF.Functions.Like(u.Name.ToLower(), $"%{normalizedTerm}%") ||
                       EF.Functions.Like(u.Native.ToLower(), $"%{normalizedTerm}%"))
            .Take(maxResults / 3)
            .ToListAsync();

        return new SearchResults(countries, divisions, urbans);
    }

    // Administrative division type analysis
    public async Task<Dictionary<string, int>> GetDivisionTypeDistributionAsync()
    {
        var query = _context.Divisions
            .GroupBy(d => EF.Property<string>(d, "type"))
            .Select(g => new { Type = g.Key, Count = g.Count() });

        var results = await query.ToListAsync();
        return results.ToDictionary(r => r.Type, r => r.Count);
    }
}

// Supporting classes
public class CountryHierarchy
{
    public Country Country { get; set; } = null!;
    public List<DivisionHierarchy> Divisions { get; set; } = new();
}

public class DivisionHierarchy  
{
    public Division Division { get; set; } = null!;
    public List<Urban> Urbans { get; set; } = new();
}

public class SearchResults
{
    public List<Country> Countries { get; set; }
    public List<Division> Divisions { get; set; }
    public List<Urban> Urbans { get; set; }

    public SearchResults(List<Country> countries, List<Division> divisions, List<Urban> urbans)
    {
        Countries = countries;
        Divisions = divisions;
        Urbans = urbans;
    }

    public int TotalResults => Countries.Count + Divisions.Count + Urbans.Count;
}
```

#### Type-Specific Query Extensions

```csharp
public static class NationQueryExtensions
{
    // Country extensions
    public static IQueryable<Country> ByContinent(this IQueryable<Country> countries, string continent)
    {
        // This would require additional continent data - example implementation
        return countries.Where(c => /* continent logic */ true);
    }

    public static IQueryable<Country> WithPopulationRange(this IQueryable<Country> countries, 
        int minPopulation, int maxPopulation = int.MaxValue)
    {
        return countries.Where(c => c.Population >= minPopulation && c.Population <= maxPopulation);
    }

    // Division extensions
    public static IQueryable<T> InCountry<T>(this IQueryable<T> divisions, string countryIso) 
        where T : Division
    {
        return divisions.Join(
            divisions.Take(1).Select(_ => countryIso), // Workaround for parameter
            d => true,
            iso => true,
            (d, iso) => d)
            .Where(d => EF.Property<string>(
                EF.Property<Country>(d, "Country"), "Iso") == countryIso);
    }

    public static IQueryable<Province> Provinces(this IQueryable<Division> divisions)
    {
        return divisions.OfType<Province>();
    }

    public static IQueryable<State> States(this IQueryable<Division> divisions)
    {
        return divisions.OfType<State>();
    }

    // Urban extensions
    public static IQueryable<T> InDivision<T>(this IQueryable<T> urbans, int divisionId) 
        where T : Urban
    {
        return urbans.Where(u => u.DivisionId == divisionId);
    }

    public static IQueryable<City> Cities(this IQueryable<Urban> urbans)
    {
        return urbans.OfType<City>();
    }

    public static IQueryable<T> WithMinimumPopulation<T>(this IQueryable<T> entities, int minPopulation)
        where T : Entity<int>
    {
        return entities.Where(e => EF.Property<int>(e, "Population") >= minPopulation);
    }
}

// Usage examples
public async Task<List<Province>> GetCanadianProvincesAsync()
{
    return await _context.Divisions
        .OfType<Province>()
        .InCountry("CA") 
        .OrderBy(p => p.Name)
        .ToListAsync();
}

public async Task<List<City>> GetLargeCitiesInStateAsync(int stateId)
{
    return await _context.Urbans
        .OfType<City>()
        .InDivision(stateId)
        .WithMinimumPopulation(100_000)
        .OrderByDescending(c => EF.Property<int>(c, "Population"))
        .ToListAsync();
}
```

### Performance Optimization

#### Query Optimization Strategies

```csharp
public class OptimizedGeographicalService
{
    private readonly NationDbContext _context;
    private readonly IMemoryCache _cache;

    public OptimizedGeographicalService(NationDbContext context, IMemoryCache cache)
    {
        _context = context;
        _cache = cache;
    }

    // Cached country lookup
    public async Task<Country?> GetCountryByIsoAsync(string iso)
    {
        var cacheKey = $"country:{iso.ToUpper()}";
        
        if (_cache.TryGetValue(cacheKey, out Country? cachedCountry))
        {
            return cachedCountry;
        }

        var country = await _context.Countries
            .FirstOrDefaultAsync(c => c.Iso == iso);

        if (country != null)
        {
            _cache.Set(cacheKey, country, TimeSpan.FromHours(24));
        }

        return country;
    }

    // Bulk operations for performance
    public async Task<Dictionary<string, List<Division>>> GetDivisionsByCountriesAsync(
        IEnumerable<string> countryIsos)
    {
        var isos = countryIsos.ToHashSet();
        
        var results = await _context.Countries
            .Where(c => isos.Contains(c.Iso))
            .Select(c => new 
            { 
                CountryIso = c.Iso,
                Divisions = _context.Divisions
                    .Where(d => d.CountryId == c.Id)
                    .ToList()
            })
            .ToListAsync();

        return results.ToDictionary(r => r.CountryIso, r => r.Divisions);
    }

    // Projected queries for minimal data transfer
    public async Task<List<PlaceSummary>> GetPlaceSummariesAsync()
    {
        return await _context.Countries
            .Select(c => new PlaceSummary
            {
                Id = c.Id,
                Type = "Country",
                Name = c.Name,
                NativeName = c.Native,
                Population = c.Population
            })
            .Union(_context.Divisions
                .Select(d => new PlaceSummary
                {
                    Id = d.Id,
                    Type = EF.Property<string>(d, "type"),
                    Name = d.Name,
                    NativeName = d.Native, 
                    Population = d.Population
                }))
            .OrderBy(p => p.Name)
            .ToListAsync();
    }

    // Batch processing for large datasets
    public async Task ProcessAllDivisionsAsync(Func<Division, Task> processor, int batchSize = 1000)
    {
        var totalCount = await _context.Divisions.CountAsync();
        var processedCount = 0;

        while (processedCount < totalCount)
        {
            var batch = await _context.Divisions
                .OrderBy(d => d.Id)
                .Skip(processedCount)
                .Take(batchSize)
                .ToListAsync();

            if (!batch.Any()) break;

            var tasks = batch.Select(processor);
            await Task.WhenAll(tasks);

            processedCount += batch.Count;
        }
    }
}

public class PlaceSummary
{
    public int Id { get; set; }
    public string Type { get; set; } = null!;
    public string Name { get; set; } = null!;
    public string NativeName { get; set; } = null!;
    public int Population { get; set; }
}
```

### Advanced Seed Data Management

#### Custom Seed Data Sources

```csharp
public interface ISeedDataSource<T>
{
    Task<IEnumerable<T>> GetDataAsync();
    string SourceName { get; }
}

public class JsonCountrySeedSource : ISeedDataSource<Country>
{
    private readonly string _jsonPath;

    public JsonCountrySeedSource(string jsonPath)
    {
        _jsonPath = jsonPath;
    }

    public string SourceName => "JSON Country Data";

    public async Task<IEnumerable<Country>> GetDataAsync()
    {
        var json = await File.ReadAllTextAsync(_jsonPath);
        var countryData = JsonSerializer.Deserialize<CountryJson[]>(json);

        return countryData?.Select(c => new Country(
            c.Id,
            c.Iso,
            c.Code,
            c.Name,
            c.Native ?? c.Name,
            c.Population
        )) ?? Enumerable.Empty<Country>();
    }

    private class CountryJson
    {
        public int Id { get; set; }
        public string Iso { get; set; } = null!;
        public int Code { get; set; }
        public string Name { get; set; } = null!;
        public string? Native { get; set; }
        public int Population { get; set; }
    }
}

public class RestApiSeedSource<T> : ISeedDataSource<T>
{
    private readonly HttpClient _httpClient;
    private readonly string _apiEndpoint;
    private readonly Func<JsonDocument, IEnumerable<T>> _parser;

    public RestApiSeedSource(HttpClient httpClient, string apiEndpoint, 
        Func<JsonDocument, IEnumerable<T>> parser)
    {
        _httpClient = httpClient;
        _apiEndpoint = apiEndpoint;
        _parser = parser;
    }

    public string SourceName => $"REST API: {_apiEndpoint}";

    public async Task<IEnumerable<T>> GetDataAsync()
    {
        var response = await _httpClient.GetAsync(_apiEndpoint);
        response.EnsureSuccessStatusCode();

        var content = await response.Content.ReadAsStringAsync();
        using var document = JsonDocument.Parse(content);
        
        return _parser(document);
    }
}
```

#### Advanced Seeding Strategy

```csharp
public class AdvancedSeedingService
{
    private readonly NationDbContext _context;
    private readonly ILogger<AdvancedSeedingService> _logger;

    public AdvancedSeedingService(NationDbContext context, ILogger<AdvancedSeedingService> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task SeedAllDataAsync(bool forceReseed = false)
    {
        using var transaction = await _context.Database.BeginTransactionAsync();
        
        try
        {
            await SeedCountriesAsync(forceReseed);
            await SeedDivisionsAsync(forceReseed);
            await SeedUrbansAsync(forceReseed);
            
            await transaction.CommitAsync();
            _logger.LogInformation("All seed data successfully applied");
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            _logger.LogError(ex, "Failed to seed data, transaction rolled back");
            throw;
        }
    }

    private async Task SeedCountriesAsync(bool forceReseed)
    {
        if (!forceReseed && await _context.Countries.AnyAsync())
        {
            _logger.LogInformation("Countries already exist, skipping seed");
            return;
        }

        if (forceReseed)
        {
            _context.Countries.RemoveRange(await _context.Countries.ToListAsync());
        }

        var sources = new ISeedDataSource<Country>[]
        {
            new JsonCountrySeedSource("data/countries.json"),
            new InMemorySeedSource<Country>("Built-in", CountrySeed.Dataset)
        };

        foreach (var source in sources)
        {
            try
            {
                var countries = await source.GetDataAsync();
                var countryList = countries.ToList();
                
                _logger.LogInformation($"Seeding {countryList.Count} countries from {source.SourceName}");
                
                foreach (var country in countryList)
                {
                    var existing = await _context.Countries.FindAsync(country.Id);
                    if (existing == null)
                    {
                        _context.Countries.Add(country);
                    }
                    else if (forceReseed)
                    {
                        _context.Entry(existing).CurrentValues.SetValues(country);
                    }
                }

                await _context.SaveChangesAsync();
                _logger.LogInformation($"Successfully seeded countries from {source.SourceName}");
                break; // Use first successful source
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, $"Failed to seed from {source.SourceName}, trying next source");
            }
        }
    }

    private async Task SeedDivisionsAsync(bool forceReseed)
    {
        var divisionSources = new Dictionary<string, Func<Task<IEnumerable<Division>>>>
        {
            ["Thailand"] = async () => ProvinceSeed.Dataset.Cast<Division>(),
            // Add more country-specific division sources
        };

        foreach (var (country, sourceFunc) in divisionSources)
        {
            try
            {
                var divisions = await sourceFunc();
                var divisionList = divisions.ToList();

                _logger.LogInformation($"Seeding {divisionList.Count} divisions for {country}");

                foreach (var division in divisionList)
                {
                    var existing = await _context.Divisions.FindAsync(division.Id);
                    if (existing == null)
                    {
                        _context.Divisions.Add(division);
                    }
                    else if (forceReseed)
                    {
                        _context.Entry(existing).CurrentValues.SetValues(division);
                    }
                }

                await _context.SaveChangesAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to seed divisions for {country}");
            }
        }
    }

    private async Task SeedUrbansAsync(bool forceReseed)
    {
        // Urban seeding logic - placeholder for future urban seed data
        _logger.LogInformation("Urban seeding not yet implemented");
        await Task.CompletedTask;
    }
}

public class InMemorySeedSource<T> : ISeedDataSource<T>
{
    private readonly IEnumerable<T> _data;

    public InMemorySeedSource(string sourceName, IEnumerable<T> data)
    {
        SourceName = sourceName;
        _data = data;
    }

    public string SourceName { get; }

    public Task<IEnumerable<T>> GetDataAsync()
    {
        return Task.FromResult(_data);
    }
}
```

### Custom Entity Types and Extensions

#### Creating Custom Division Types

```csharp
// Custom division type with additional properties
public class Prefecture : Division
{
    public Prefecture() { }

    public Prefecture(int id, int countryId, string iso, string name, string native, 
        int population, string prefecturalCode, DateTime establishedDate)
        : base(id, countryId, iso, name, native, population)
    {
        PrefecturalCode = prefecturalCode;
        EstablishedDate = establishedDate;
    }

    public string PrefecturalCode { get; set; } = null!;
    public DateTime EstablishedDate { get; set; }
}

// Configuration for custom entity
public class PrefectureConfiguration : IEntityTypeConfiguration<Prefecture>
{
    public void Configure(EntityTypeBuilder<Prefecture> builder)
    {
        builder.Property(p => p.PrefecturalCode)
            .HasMaxLength(10)
            .IsRequired();

        builder.HasIndex(p => p.PrefecturalCode)
            .IsUnique();

        builder.Property(p => p.EstablishedDate)
            .HasColumnType("date");
    }
}

// Usage
public class ExtendedNationDbContext : NationDbContext
{
    public DbSet<Prefecture> Prefectures { get; set; } = null!;

    public ExtendedNationDbContext(DbContextOptions<ExtendedNationDbContext> options) 
        : base(options) { }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        
        modelBuilder.ApplyConfiguration(new PrefectureConfiguration());
    }
}
```

#### Custom Repository Pattern

```csharp
public interface INationRepository<T> where T : Entity<int>
{
    Task<T?> GetByIdAsync(int id);
    Task<IEnumerable<T>> GetAllAsync();
    Task<IEnumerable<T>> FindAsync(Expression<Func<T, bool>> predicate);
    Task<T> AddAsync(T entity);
    Task UpdateAsync(T entity);
    Task DeleteAsync(int id);
}

public class NationRepository<T> : INationRepository<T> where T : Entity<int>
{
    protected readonly NationDbContext Context;
    protected readonly DbSet<T> DbSet;

    public NationRepository(NationDbContext context)
    {
        Context = context;
        DbSet = context.Set<T>();
    }

    public virtual async Task<T?> GetByIdAsync(int id)
    {
        return await DbSet.FindAsync(id);
    }

    public virtual async Task<IEnumerable<T>> GetAllAsync()
    {
        return await DbSet.ToListAsync();
    }

    public virtual async Task<IEnumerable<T>> FindAsync(Expression<Func<T, bool>> predicate)
    {
        return await DbSet.Where(predicate).ToListAsync();
    }

    public virtual async Task<T> AddAsync(T entity)
    {
        var result = await DbSet.AddAsync(entity);
        await Context.SaveChangesAsync();
        return result.Entity;
    }

    public virtual async Task UpdateAsync(T entity)
    {
        DbSet.Update(entity);
        await Context.SaveChangesAsync();
    }

    public virtual async Task DeleteAsync(int id)
    {
        var entity = await GetByIdAsync(id);
        if (entity != null)
        {
            DbSet.Remove(entity);
            await Context.SaveChangesAsync();
        }
    }
}

// Specialized repositories
public interface ICountryRepository : INationRepository<Country>
{
    Task<Country?> GetByIsoAsync(string iso);
    Task<IEnumerable<Country>> GetByRegionAsync(string region);
}

public class CountryRepository : NationRepository<Country>, ICountryRepository
{
    public CountryRepository(NationDbContext context) : base(context) { }

    public async Task<Country?> GetByIsoAsync(string iso)
    {
        return await DbSet.FirstOrDefaultAsync(c => c.Iso == iso);
    }

    public async Task<IEnumerable<Country>> GetByRegionAsync(string region)
    {
        // Implementation would depend on region data structure
        throw new NotImplementedException("Region data not yet available");
    }
}
```

### Integration Testing

```csharp
public class NationIntegrationTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;
    private readonly NationDbContext _context;

    public NationIntegrationTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
        
        var scope = factory.Services.CreateScope();
        _context = scope.ServiceProvider.GetRequiredService<NationDbContext>();
    }

    [Fact]
    public async Task CanCreateCompleteGeographicalHierarchy()
    {
        // Arrange
        var country = new Country(999, "TS", 999, "Test Country", "Test Native", 1000000);
        var division = new Province(9999, 999, "TS-01", "Test Province", "Test Native Province", 500000);
        var urban = new City 
        { 
            DivisionId = 9999, 
            Name = "Test City", 
            Native = "Test Native City", 
            Iso = "TS-01-01" 
        };

        // Act
        _context.Countries.Add(country);
        await _context.SaveChangesAsync();

        _context.Divisions.Add(division);
        await _context.SaveChangesAsync();

        _context.Urbans.Add(urban);
        await _context.SaveChangesAsync();

        // Assert
        var savedCountry = await _context.Countries.FindAsync(999);
        var savedDivision = await _context.Divisions.FindAsync(9999);
        var savedUrban = await _context.Urbans.FirstAsync(u => u.Name == "Test City");

        Assert.NotNull(savedCountry);
        Assert.NotNull(savedDivision);
        Assert.NotNull(savedUrban);
        Assert.Equal(999, savedDivision.CountryId);
        Assert.Equal(9999, savedUrban.DivisionId);
    }

    [Fact]
    public async Task SeedDataIsAccessible()
    {
        // Act
        var countries = CountrySeed.Dataset;
        var provinces = ProvinceSeed.Dataset;

        // Assert
        Assert.NotEmpty(countries);
        Assert.NotEmpty(provinces);
        Assert.Contains(countries, c => c.Iso == "TH");
        Assert.Contains(provinces, p => p.Iso == "BKK");
    }
}
```

This advanced usage documentation covers sophisticated Entity Framework Core integration patterns, performance optimization techniques, advanced seeding strategies, and extension points for customization. The examples demonstrate production-ready patterns for working with the Nation library in complex scenarios.