Clear-Host

Write-Host "==================================================" -ForegroundColor Yellow
Write-Host "         TOOL UNLOCK MINECRAFT" -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Yellow

# ============================================
# 1. XAC DINH THU MUC HIEN TAI (DUA TREN UNG DUNG)
# ============================================
# Cach 1: Lay thu muc cua script dang chay (neu chay tu file)
$currentFolder = $PSScriptRoot

# Cach 2: Neu $PSScriptRoot rong (chay tu Internet), dung thu muc lam viec hien tai
if ([string]::IsNullOrEmpty($currentFolder)) {
    $currentFolder = (Get-Location).Path
}

# Cach 3: Neu van rong, dung thu muc temp
if ([string]::IsNullOrEmpty($currentFolder)) {
    $currentFolder = $env:TEMP
}

Write-Host "[INFO] Current folder: $currentFolder" -ForegroundColor Cyan
Write-Host "[INFO] Working directory: $(Get-Location)" -ForegroundColor Gray

# ============================================
# 2. DUONG DAN MODS
# ============================================
$modsPath = "$env:APPDATA\Minecraft Bedrock\mods"
Write-Host "[INFO] Mods folder: $modsPath" -ForegroundColor Cyan

if (Test-Path $modsPath) {
    Write-Host "[OK] Mods folder exists" -ForegroundColor Green
} else {
    New-Item -ItemType Directory -Path $modsPath -Force | Out-Null
    Write-Host "[OK] Created mods folder" -ForegroundColor Green
}

# ============================================
# 3. TIM THU MUC MINECRAFT
# ============================================
Write-Host ""
Write-Host "[INFO] Searching for Minecraft folder..." -ForegroundColor Cyan

$contentPath = $null

$drives = Get-PSDrive -PSProvider FileSystem
foreach ($drive in $drives) {
    $xboxPath = Join-Path $drive.Root "XboxGames"
    if (Test-Path $xboxPath) {
        $folders = Get-ChildItem -Path $xboxPath -Directory -ErrorAction SilentlyContinue
        foreach ($folder in $folders) {
            $testPath = Join-Path $folder.FullName "Content"
            if (Test-Path $testPath) {
                $minecraftDll = Join-Path $testPath "Minecraft.Windows.dll"
                if (Test-Path $minecraftDll) {
                    $contentPath = $testPath
                    Write-Host "  [FOUND] $contentPath" -ForegroundColor Green
                    break
                }
            }
        }
    }
    if ($contentPath) { break }
}

if (-not $contentPath) {
    Write-Host ""
    Write-Host "[ERROR] Cannot find Minecraft folder!" -ForegroundColor Red
    Write-Host "[INFO] Please enter the path manually." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Example: D:\XboxGames\7792D9CE-355A-493C-AFBD-768F4A77C3B0\Content" -ForegroundColor Gray
    Write-Host ""
    
    $manualPath = Read-Host "Enter Minecraft folder path"
    
    if (Test-Path $manualPath) {
        $contentPath = $manualPath
        Write-Host "[OK] Using: $contentPath" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Path not found!" -ForegroundColor Red
        Write-Host "Press any key to exit..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit
    }
}

# ============================================
# 4. COPY FILE DLL - Tim o nhieu vi tri
# ============================================
Write-Host ""
Write-Host "Copying DLL files from local folder..." -ForegroundColor Cyan

# Danh sach cac thu muc can tim file
$searchPaths = @(
    $currentFolder,                                          # Thu muc script
    (Get-Location).Path,                                     # Thu muc lam viec hien tai
    "C:\Users\huy\Downloads\Trial.Unlock-ggAng",            # Duong dan cu
    $env:TEMP,                                               # Thu muc temp
    "$env:USERPROFILE\Downloads\Trial.Unlock-ggAng",        # Thu muc Downloads
    "$env:USERPROFILE\Desktop",                              # Desktop
    "C:\Users\huy\Downloads"                                 # Downloads
)

$files = @(
    @{
        SourceNames = @("TrialUnlock.dll", "unlock.dll")
        Dest = "$modsPath\unlock.dll"
        Name = "unlock.dll"
    },
    @{
        SourceNames = @("vcruntime140_1.dll")
        Dest = "$contentPath\vcruntime140_1.dll"
        Name = "vcruntime140_1.dll"
    },
    @{
        SourceNames = @("ModLoader.dll")
        Dest = "$contentPath\ModLoader.dll"
        Name = "ModLoader.dll"
    }
)

foreach ($file in $files) {
    $found = $false
    
    # Tim file trong tat ca cac thu muc
    foreach ($searchPath in $searchPaths) {
        if (-not (Test-Path $searchPath)) { continue }
        
        foreach ($sourceName in $file.SourceNames) {
            $sourceFile = Join-Path $searchPath $sourceName
            if (Test-Path $sourceFile) {
                try {
                    Copy-Item -Path $sourceFile -Destination $file.Dest -Force -ErrorAction Stop
                    Write-Host "  - Copying from: $sourceFile" -ForegroundColor Gray
                    Write-Host "    -> $($file.Name) ... [OK]" -ForegroundColor Green
                    $found = $true
                    break
                } catch {
                    Write-Host "  - Copying $sourceName -> $($file.Name) ... [FAILED - Access denied]" -ForegroundColor Red
                    Write-Host "    Try running PowerShell as Administrator!" -ForegroundColor Yellow
                    $found = $true
                    break
                }
            }
        }
        if ($found) { break }
    }
    
    if (-not $found) {
        Write-Host "  - Copying $($file.Name) ... [FAILED - File not found]" -ForegroundColor Red
        Write-Host "    Please make sure the file exists in one of these locations:" -ForegroundColor Yellow
        foreach ($path in $searchPaths) {
            Write-Host "      - $path" -ForegroundColor Gray
        }
    }
}

# ============================================
# 5. KIEM TRA KET QUA
# ============================================
Write-Host ""
Write-Host "==================================================" -ForegroundColor Green
Write-Host "[OK] INSTALLATION COMPLETE!" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Files copied to:" -ForegroundColor Yellow
Write-Host "  - $modsPath\unlock.dll" -ForegroundColor Gray
Write-Host "  - $contentPath\vcruntime140_1.dll" -ForegroundColor Gray
Write-Host "  - $contentPath\ModLoader.dll" -ForegroundColor Gray
Write-Host ""

Write-Host "Verifying files..." -ForegroundColor Cyan

$verifyFiles = @(
    "$modsPath\unlock.dll",
    "$contentPath\vcruntime140_1.dll",
    "$contentPath\ModLoader.dll"
)

$allExist = $true
foreach ($file in $verifyFiles) {
    if (Test-Path $file) {
        $size = (Get-Item $file).Length
        Write-Host "  [OK] $file ($size bytes)" -ForegroundColor Green
    } else {
        Write-Host "  [MISSING] $file" -ForegroundColor Red
        $allExist = $false
    }
}

if ($allExist) {
    Write-Host ""
    Write-Host "[OK] ALL FILES COPIED SUCCESSFULLY!" -ForegroundColor Green
    Write-Host "[OK] You can now open Minecraft!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "[WARNING] Some files are missing!" -ForegroundColor Yellow
    Write-Host "Please copy the DLL files manually to the correct folders." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
