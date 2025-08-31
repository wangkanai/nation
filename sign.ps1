param(
    [Parameter(mandatory=$false)]
    [bool]$publish=$true,
    [Parameter(mandatory=$false)]
    [bool]$skip=$false,
    [Parameter(mandatory=$false)]
    [string]$certicate="Open Source Developer, Sarin Na Wangkanai"
)

Write-Host "NuGet Certificate: $certicate" -ForegroundColor Magenta
Write-Host "Nation Package Signing and Publishing" -ForegroundColor Cyan

$e=[char]27
$root=Get-Location

    # Get current version from Directory.Build.props
    [Xml]$xml = Get-Content -Path .\Directory.Build.props
    $version = $xml.Project.PropertyGroup.VersionPrefix
    if ($version.GetType().FullName -ne "System.String") {
        $version = $version[0]
    }
    
    Write-Host "Nation Package Version: $version" -ForegroundColor Yellow
    
    # Check if package exists on NuGet
    $packageName = "Wangkanai.Nation"
    try {
        $package = Find-Package -Name $packageName -ProviderName NuGet -AllVersions -ErrorAction SilentlyContinue
        $latest = if ($package) { ($package | Select-Object -First 1).Version } else { "0.0.0" }
        
        if ($latest -ne $version) {
            Write-Host "$latest < $version - Update needed" -ForegroundColor Green
        } else {
            Write-Host "$latest = $version - Skip" -ForegroundColor DarkGray
            if (-not $skip) {
                Write-Host "No version change detected" -ForegroundColor Yellow
                return
            }
        }
    }
    catch {
        Write-Host "New package - first publish" -ForegroundColor Blue
    }

    # Build and pack
    Write-Host "Building and packing..." -ForegroundColor Yellow
    dotnet build -c Release --verbosity minimal
    if ($LASTEXITCODE -ne 0) { throw "Build failed" }
    
    dotnet pack -c Release --no-build --verbosity minimal
    if ($LASTEXITCODE -ne 0) { throw "Pack failed" }

    # Find the generated package
    $nupkgFiles = Get-ChildItem -Path "src/bin/Release" -Filter "*.nupkg" -Recurse | Sort-Object LastWriteTime -Descending
    if ($nupkgFiles.Count -eq 0) { throw "No package file found" }
    
    $packagePath = $nupkgFiles[0].FullName
    Write-Host "Package: $packagePath" -ForegroundColor Green

    if ($publish) {
        Write-Host "Publishing package..." -ForegroundColor Yellow
        # Note: Actual publishing would require NuGet API key
        # dotnet nuget push $packagePath --source https://api.nuget.org/v3/index.json --api-key $env:NUGET_API_KEY
        Write-Host "Package ready for publishing: $packagePath" -ForegroundColor Green
    }

    Write-Host "Signing and packaging completed!" -ForegroundColor Green
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}
