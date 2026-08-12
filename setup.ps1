Clear-Host

Write-Host "==================================================" -ForegroundColor Yellow
Write-Host "         TOOL UNLOCK MINECRAFT" -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Yellow

$currentFolder = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Host "[INFO] Current folder: $currentFolder" -ForegroundColor Cyan

# ============================================
# 1. Tao thu muc mods
# ============================================
$modsPath = "$env:APPDATA\Minecraft Bedrock\mods"

if (Test-Path $modsPath) {
    Write-Host "[OK] Mods folder exists" -ForegroundColor Green
} else {
    New-Item -ItemType Directory -Path $modsPath -Force | Out-Null
    Write-Host "[OK] Created mods folder" -ForegroundColor Green
}

# ============================================
# 2. TU DONG TIM THU MUC MINECRAFT
# ============================================
Write-Host ""
Write-Host "[INFO] Searching for Minecraft folder..." -ForegroundColor Cyan

$contentPath = $null
$foundPaths = @()

# Cach 1: Tim trong thu muc XboxGames (Game Pass)
$drives = Get-PSDrive -PSProvider FileSystem
foreach ($drive in $drives) {
    $xboxPath = Join-Path $drive.Root "XboxGames"
    if (Test-Path $xboxPath) {
        $folders = Get-ChildItem -Path $xboxPath -Directory -ErrorAction SilentlyContinue
        foreach ($folder in $folders) {
            $testPath = Join-Path $folder.FullName "Content"
            if (Test-Path $testPath) {
                # Kiem tra xem co file Minecraft.exe hoac DLL dac trung khong
                $minecraftExe = Join-Path $testPath "Minecraft.exe"
                $minecraftDll = Join-Path $testPath "Minecraft.Windows.dll"
                if ((Test-Path $minecraftExe) -or (Test-Path $minecraftDll)) {
                    $foundPaths += $testPath
                    Write-Host "  [FOUND] $testPath" -ForegroundColor Green
                }
            }
        }
    }
}

# Cach 2: Tim trong thu muc WindowsApps (cach cai cu hon)
$programFiles = @("$env:ProgramFiles\WindowsApps", "${env:ProgramFiles(x86)}\WindowsApps")
foreach ($pf in $programFiles) {
    if (Test-Path $pf) {
        $folders = Get-ChildItem -Path $pf -Directory -ErrorAction SilentlyContinue
        foreach ($folder in $folders) {
            if ($folder.Name -like "*Minecraft*") {
                $testPath = $folder.FullName
                # Kiem tra xem co file Minecraft.exe khong
                $minecraftExe = Join-Path $testPath "Minecraft.exe"
                if (Test-Path $minecraftExe) {
                    $foundPaths += $testPath
                    Write-Host "  [FOUND] $testPath" -ForegroundColor Green
                }
            }
        }
    }
}

# Cach 3: Tim trong thu muc cai dat thong thuong (TLauncher, PCL, ...)
$commonPaths = @(
    "C:\Program Files\Minecraft",
    "C:\Program Files (x86)\Minecraft",
    "D:\Program Files\Minecraft",
    "E:\Program Files\Minecraft",
    "$env:USERPROFILE\Desktop\Minecraft",
    "$env:USERPROFILE\Downloads\Minecraft"
)

foreach ($path in $commonPaths) {
    if (Test-Path $path) {
        $minecraftExe = Join-Path $path "Minecraft.exe"
        if (Test-Path $minecraftExe) {
            $foundPaths += $path
            Write-Host "  [FOUND] $path" -ForegroundColor Green
        }
    }
}

# ============================================
# 3. CHON DUONG DAN
# ============================================
if ($foundPaths.Count -eq 0) {
    Write-Host ""
    Write-Host "[ERROR] Cannot find Minecraft folder!" -ForegroundColor Red
    Write-Host "[ERROR] Please enter the path manually." -ForegroundColor Yellow
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
} elseif ($foundPaths.Count -eq 1) {
    $contentPath = $foundPaths[0]
    Write-Host ""
    Write-Host "[OK] Found Minecraft at: $contentPath" -ForegroundColor Green
} else {
    # Nhieu hon 1 duong dan -> cho nguoi dung chon
    Write-Host ""
    Write-Host "[INFO] Multiple Minecraft folders found!" -ForegroundColor Yellow
    Write-Host "Please select the correct one:" -ForegroundColor Yellow
    Write-Host ""
    
    for ($i = 0; $i -lt $foundPaths.Count; $i++) {
        Write-Host "  [$i] $($foundPaths[$i])" -ForegroundColor Cyan
    }
    Write-Host ""
    
    $choice = Read-Host "Enter number (0-$($foundPaths.Count - 1))"
    
    if ($choice -match "^\d+$" -and [int]$choice -ge 0 -and [int]$choice -lt $foundPaths.Count) {
        $contentPath = $foundPaths[[int]$choice]
        Write-Host "[OK] Using: $contentPath" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Invalid choice!" -ForegroundColor Red
        Write-Host "Press any key to exit..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit
    }
}

# ============================================
# 4. COPY FILE DLL
# ============================================
Write-Host ""
Write-Host "Copying DLL files from local folder..." -ForegroundColor Cyan

# Danh sach cac file can copy (tu ten nguon -> ten dich)
$fileMappings = @(
    @{
        Source = @("TrialUnlock.dll", "unlock.dll")
        Dest = Join-Path $modsPath "unlock.dll"
        Name = "unlock.dll"
    },
    @{
        Source = @("vcruntime140_1.dll")
        Dest = Join-Path $contentPath "vcruntime140_1.dll"
        Name = "vcruntime140_1.dll"
    },
    @{
        Source = @("ModLoader.dll")
        Dest = Join-Path $contentPath "ModLoader.dll"
        Name = "ModLoader.dll"
    }
)

$allSuccess = $true

foreach ($mapping in $fileMappings) {
    $found = $false
    foreach ($sourceName in $mapping.Source) {
        $sourceFile = Join-Path $currentFolder $sourceName
        if (Test-Path $sourceFile) {
            Copy-Item -Path $sourceFile -Destination $mapping.Dest -Force -ErrorAction SilentlyContinue
            Write-Host "  - Copying $sourceName -> $($mapping.Name) ... [OK]" -ForegroundColor Green
            $found = $true
            break
        }
    }
    if (-not $found) {
        Write-Host "  - Copying $($mapping.Name) ... [FAILED - File not found]" -ForegroundColor Red
        $allSuccess = $false
    }
}

# ============================================
# 5. KET QUA
# ============================================
Write-Host ""
Write-Host "==================================================" -ForegroundColor Green
if ($allSuccess) {
    Write-Host "[OK] INSTALLATION COMPLETE!" -ForegroundColor Green
} else {
    Write-Host "[WARNING] SOME FILES FAILED!" -ForegroundColor Yellow
}
Write-Host "==================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Files copied to:" -ForegroundColor Yellow
Write-Host "  - $($fileMappings[0].Dest)" -ForegroundColor Gray
Write-Host "  - $($fileMappings[1].Dest)" -ForegroundColor Gray
Write-Host "  - $($fileMappings[2].Dest)" -ForegroundColor Gray
Write-Host ""
Write-Host "[OK] You can now open Minecraft!" -ForegroundColor Green
Write-Host ""

Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")