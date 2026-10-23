param(
    [switch]$BuildInstaller,
    [switch]$Clean,
    [string]$OutputDirectory = "dist\windows"
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "   Mazikty Music - Building Windows Release" -ForegroundColor Yellow
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""

$ProjectRoot = (Get-Item $PSScriptRoot).Parent.FullName
Set-Location $ProjectRoot

# 1. Clean ephemeral directories to prevent Flutter symlink collision bugs (OS Error 183)
if (Test-Path "windows\flutter\ephemeral") {
    Remove-Item -Path "windows\flutter\ephemeral" -Recurse -Force -ErrorAction SilentlyContinue
}
if (Test-Path "linux\flutter\ephemeral") {
    Remove-Item -Path "linux\flutter\ephemeral" -Recurse -Force -ErrorAction SilentlyContinue
}

# Clean build artifacts if requested
if ($Clean) {
    Write-Host "Cleaning previous build artifacts..." -ForegroundColor Yellow
    flutter clean
}

# 2. Get packages
Write-Host "Fetching dependencies (flutter pub get)..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to run flutter pub get"
    exit $LASTEXITCODE
}

# 3. Build Windows Release
Write-Host "Building Windows Release (flutter build windows --release)..." -ForegroundColor Green
flutter build windows --release
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to build Windows release!"
    exit $LASTEXITCODE
}

# 4. Locate Build Output
$PossibleBuildPaths = @(
    (Join-Path $ProjectRoot "build\windows\x64\runner\Release"),
    (Join-Path $ProjectRoot "build\windows\runner\Release")
)

$BuildPath = $null
foreach ($path in $PossibleBuildPaths) {
    if (Test-Path (Join-Path $path "mazikty.exe")) {
        $BuildPath = $path
        break
    }
}

if (-not $BuildPath) {
    Write-Error "Could not find mazikty.exe in build directories!"
    exit 1
}

Write-Host "Build output found at: $BuildPath" -ForegroundColor Green

# 5. Copy to Output Directory
$TargetDir = Join-Path $ProjectRoot $OutputDirectory
$AppBundleDir = Join-Path $TargetDir "Mazikty"

if (Test-Path $AppBundleDir) {
    Remove-Item $AppBundleDir -Recurse -Force
}
New-Item -ItemType Directory -Path $AppBundleDir -Force | Out-Null

Write-Host "Copying application bundle to: $AppBundleDir..." -ForegroundColor Yellow
Copy-Item -Path "$BuildPath\*" -Destination $AppBundleDir -Recurse -Force

# Create launch helper
$LaunchBat = "@echo off`r`nstart `"`" `"%~dp0mazikty.exe`""
Set-Content -Path (Join-Path $AppBundleDir "Run-Mazikty.bat") -Value $LaunchBat -Encoding ASCII

Write-Host "Application bundle prepared successfully!" -ForegroundColor Green

# 6. Build Installer if requested
if ($BuildInstaller) {
    Write-Host ""
    Write-Host "Packaging Windows distribution..." -ForegroundColor Cyan
    
    $IsccPaths = @(
        "iscc",
        "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
        "${env:ProgramFiles}\Inno Setup 6\ISCC.exe",
        "${env:LOCALAPPDATA}\Programs\Inno Setup 6\ISCC.exe"
    )

    $IsccExe = $null
    foreach ($cand in $IsccPaths) {
        if (Get-Command $cand -ErrorAction SilentlyContinue) {
            $IsccExe = $cand
            break
        }
        if (Test-Path $cand) {
            $IsccExe = $cand
            break
        }
    }

    $IssFile = Join-Path $ProjectRoot "tool\installer.iss"

    if ($IsccExe -and (Test-Path $IssFile)) {
        Write-Host "Found Inno Setup at: $IsccExe" -ForegroundColor Green
        Write-Host "Compiling Windows installer..." -ForegroundColor Yellow
        
        $InstallerOutputDir = Join-Path $ProjectRoot "$OutputDirectory\Installer"
        if (-not (Test-Path $InstallerOutputDir)) {
            New-Item -ItemType Directory -Path $InstallerOutputDir -Force | Out-Null
        }

        & $IsccExe "/DAppSourceDir=$AppBundleDir" "/DOutputDir=$InstallerOutputDir" $IssFile

        if ($LASTEXITCODE -eq 0) {
            Write-Host "Installer created successfully in: $InstallerOutputDir" -ForegroundColor Green
        } else {
            Write-Warning "Inno Setup compilation failed. Creating ZIP archive fallback."
            $IsccExe = $null
        }
    }

    if (-not $IsccExe) {
        $ZipName = "Mazikty-Windows-v1.0.0.zip"
        $ZipPath = Join-Path $TargetDir $ZipName
        if (Test-Path $ZipPath) {
            Remove-Item $ZipPath -Force
        }
        Write-Host "Packaging standalone ZIP archive: $ZipPath..." -ForegroundColor Yellow
        Compress-Archive -Path "$AppBundleDir\*" -DestinationPath $ZipPath -Force
        Write-Host "Standalone ZIP created successfully: $ZipPath" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "   Build completed successfully! Output: $TargetDir" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Cyan
