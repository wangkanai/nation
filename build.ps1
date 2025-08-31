# Nation Repository Build Script

Write-Host "Building Nation repository..." -ForegroundColor Cyan

try {
    # Restore dependencies
    Write-Host "Restoring dependencies..." -ForegroundColor Yellow
    dotnet restore --verbosity minimal
    if ($LASTEXITCODE -ne 0) { throw "Restore failed" }

    # Build the solution
    Write-Host "Building solution..." -ForegroundColor Yellow
    dotnet build --no-restore -c Release --verbosity minimal
    if ($LASTEXITCODE -ne 0) { throw "Build failed" }

    # Run tests
    Write-Host "Running tests..." -ForegroundColor Yellow
    dotnet test --no-build -c Release --verbosity minimal --logger console
    if ($LASTEXITCODE -ne 0) { throw "Tests failed" }

    Write-Host "Build completed successfully!" -ForegroundColor Green
}
catch {
    Write-Host "Build failed: $_" -ForegroundColor Red
    exit 1
}
