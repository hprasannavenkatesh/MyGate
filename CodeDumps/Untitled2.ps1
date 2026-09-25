<#
.SYNOPSIS
    Dumps all source code files into separate text files per project type.
.DESCRIPTION
    Scans Flutter, React, and .NET project directories, excludes
    build/artifact/dependency folders, and writes file contents into
    separate .txt dumps with clear headers and separators.
.USAGE
    1. Set the 3 project root paths below.
    2. Run:  .\Generate-CodeDump.ps1
    3. Output files appear in the script directory (or set $OutputDir).
#>

# =====================================================================
#  CONFIGURATION — Adjust these paths to match your machine
# =====================================================================

 $FlutterProjectPath  = "C:\MyGateApp\mygate_app"
 $ReactProjectPath    = "C:\MyGateApp\src\Client"
 $DotNetProjectPath   = "C:\MyGateApp\src\Services"
  $DotNetProjectPath1   = "C:\MyGateApp\src\BuildingBlocks"

 $OutputDir           = "C:\MyGateApp\CodeDumps"   # Where dump files land
 $Timestamp           = Get-Date -Format "yyyyMMdd_HHmmss"

# =====================================================================
#  EXCLUSION RULES PER PROJECT TYPE
# =====================================================================

# --- Flutter ---
 $FlutterExcludeDirs = @(
    "build", ".dart_tool", ".pub-cache", ".pub-packages",
    ".packages", ".flutter-plugins", ".flutter-plugins-dependencies",
    ".gradle", ".idea", ".vscode", "android\.gradle",
    "ios\Pods", "ios\.symlinks", "ios\Runner.xcworkspace",
    "ios\Runner.xcodeproj\project.xcworkspace",
    ".fvm", ".dart_tool", "windows\flutter\ephemeral",
    "linux\flutter\ephemeral", "macos\Flutter\ephemeral",
    "web\icons", ".git"
)
 $FlutterExcludeFiles = @(
    "*.lock", "*.g.dart", "*.freezed.dart", "*.config",
    "*.abi.json", "*.symlink", "*.stamp"
)
 $FlutterIncludeExts  = @(
    ".dart", ".yaml", ".json", ".xml", ".gradle", ".properties",
    ".plist", ".pbxproj", ".swift", ".kt", ".java", ".html",
    ".css", ".js", ".cmake", ".txt", ".md", ".toml", ".cfg",
    ".ini", ".sh", ".bat", ".ps1", ".gitignore", ".env.example"
)

# --- React ---
 $ReactExcludeDirs = @(
    "node_modules", "dist", "build", ".cache", ".next",
    ".nuxt", "coverage", ".storybook-static", "out",
    ".turbo", ".vercel", ".git", ".husky", "__snapshots__",
    "public\fonts", "public\images", "assets\images", "assets\fonts"
)
 $ReactExcludeFiles = @(
    "*.lock", "*.map", "*.min.js", "*.min.css", "*.bundle.js",
    "*.chunk.js", "*.woff", "*.woff2", "*.ttf", "*.eot",
    "*.ico", "*.png", "*.jpg", "*.jpeg", "*.gif", "*.svg",
    "*.webp", "*.mp4", "*.mp3", "*.wav"
)
 $ReactIncludeExts  = @(
    ".js", ".jsx", ".ts", ".tsx", ".json", ".css", ".scss",
    ".sass", ".less", ".html", ".md", ".yaml", ".yml",
    ".env", ".env.local", ".env.example", ".gitignore",
    ".eslintrc*", ".prettierrc*", ".babelrc*", ".editorconfig",
    ".txt", ".sh", ".bat", ".ps1", ".cfg", ".ini", ".toml",
    ".graphql", ".gql", ".prisma", ".sql"
)

# --- .NET ---
 $DotNetExcludeDirs = @(
    "bin", "obj", ".vs", "packages", "TestResults",
    ".git", ".idea", ".vscode", "Migrations",
    "wwwroot\lib", "wwwroot\dist", "wwwroot\css\lib",
    "node_modules", ".nuget", ".config"
)
 $DotNetExcludeFiles = @(
    "*.lock", "*.suo", "*.user", "*.userosscache",
    "*.dll", "*.pdb", "*.exe", "*.cache", "*.min.js",
    "*.min.css", "*.woff", "*.woff2", "*.ttf", "*.eot",
    "*.ico", "*.png", "*.jpg", "*.jpeg", "*.gif", "*.svg"
)
 $DotNetIncludeExts  = @(
    ".cs", ".cshtml", ".razor", ".vb", ".fs", ".fsx",
    ".csproj", ".vbproj", ".fsproj", ".sln", ".slnf",
    ".json", ".xml", ".yaml", ".yml", ".config",
    ".appsettings*", ".env", ".env.example",
    ".md", ".txt", ".sh", ".bat", ".ps1", ".sql",
    ".proto", ".graphql", ".gql", ".dockerfile",
    ".gitignore", ".editorconfig", ".targets", ".props"
)

# =====================================================================
#  HELPER FUNCTIONS
# =====================================================================

function Resolve-RelativePath {
    param([string]$FullPath, [string]$RootPath)
    return $FullPath.Substring($RootPath.Length).TrimStart("\", "/")
}

function Test-ShouldExcludeDir {
    param([string]$DirName, [string[]]$ExcludeDirs)
    foreach ($excl in $ExcludeDirs) {
        $pattern = $excl.Split("\")[-1]   # match on leaf folder name
        if ($DirName -like $pattern) { return $true }
    }
    return $false
}

function Test-ShouldExcludeFile {
    param([string]$FileName, [string[]]$ExcludeFiles)
    foreach ($excl in $ExcludeFiles) {
        if ($FileName -like $excl) { return $true }
    }
    return $false
}

function Test-ShouldIncludeFile {
    param([string]$FileName, [string[]]$IncludeExts)
    $ext = [System.IO.Path]::GetExtension($FileName).ToLower()
    if ($IncludeExts.Count -eq 0) { return $true }
    # Special handling for dotfiles like .gitignore, .env.example
    if ([System.IO.Path]::GetFileName($FileName).StartsWith(".")) {
        $fullName = [System.IO.Path]::GetFileName($FileName).ToLower()
        foreach ($inc in $IncludeExts) {
            if ($fullName -like $inc.TrimStart("*")) { return $true }
        }
    }
    return $IncludeExts -contains $ext
}

# Approx max file size to read as text (skip huge / binary files)
 $MaxFileReadBytes = 1MB

function Get-FileContentSafe {
    param([string]$FilePath)
    try {
        $len = (Get-Item $FilePath).Length
        if ($len -gt $MaxFileReadBytes) {
            return "[SKIPPED: File exceeds 1 MB ($len bytes)]"
        }
        # Quick binary detection — read first 8 KB
        $bytes = [System.IO.File]::ReadAllBytes($FilePath)
        $checkLen = [Math]::Min($bytes.Length, 8192)
        $nullCount = 0
        for ($i = 0; $i -lt $checkLen; $i++) {
            if ($bytes[$i] -eq 0) { $nullCount++ }
        }
        # If > 5 % null bytes → almost certainly binary
        if ($checkLen -gt 0 -and ($nullCount / $checkLen) -gt 0.05) {
            return "[SKIPPED: Detected binary content]"
        }
        return [System.IO.File]::ReadAllText($FilePath)
    }
    catch {
        return "[ERROR reading file: $($_.Exception.Message)]"
    }
}

# =====================================================================
#  CORE DUMP FUNCTION
# =====================================================================

function Export-ProjectCodeDump {
    param(
        [string]$ProjectPath,
        [string]$ProjectLabel,
        [string[]]$ExcludeDirs,
        [string[]]$ExcludeFiles,
        [string[]]$IncludeExts,
        [string]$OutputFile
    )

    if (-not (Test-Path $ProjectPath)) {
        Write-Warning "[$ProjectLabel] Path not found: $ProjectPath — skipping."
        return
    }

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  Scanning: $ProjectLabel" -ForegroundColor Cyan
    Write-Host "  Root   : $ProjectPath" -ForegroundColor Cyan
    Write-Host "  Output : $OutputFile" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

      # --- AFTER (fixed) ---
    $allFiles = Get-ChildItem -Path $ProjectPath -File -Recurse -ErrorAction SilentlyContinue | Where-Object {
        $file = $_
        $relativePath = Resolve-RelativePath -FullPath $file.FullName -RootPath $ProjectPath

        # Check directory exclusions
        # FIX 1: Use -split with regex char class instead of .Split()
        $dirParts = $relativePath -split '[\\/]'

        $dirExcluded = $false
        # FIX 2: Safely slice — only check directory segments, not the filename
        #        For root-level files (Count=1), there are no dirs to check
        $dirSegmentCount = [Math]::Max(0, $dirParts.Count - 1)
        if ($dirSegmentCount -gt 0) {
            foreach ($part in $dirParts[0..($dirSegmentCount - 1)]) {
                if (Test-ShouldExcludeDir -DirName $part -ExcludeDirs $ExcludeDirs) {
                    $dirExcluded = $true
                    break
                }
            }
        }
        if ($dirExcluded) { return $false }

        # Check file-name exclusions
        if (Test-ShouldExcludeFile -FileName $file.Name -ExcludeFiles $ExcludeFiles) { return $false }

        # Check extension inclusion
        if (-not (Test-ShouldIncludeFile -FileName $file.Name -IncludeExts $IncludeExts)) { return $false }

        return $true
    }

    # Sort for consistent output
    $allFiles = $allFiles | Sort-Object FullName

    $fileCount = $allFiles.Count
    Write-Host "  Found $fileCount files to dump." -ForegroundColor Green

    # Write the dump
    $sb = [System.Text.StringBuilder]::new()

    [void]$sb.AppendLine("╔══════════════════════════════════════════════════════════════╗")
    [void]$sb.AppendLine("║  CODE DUMP — $ProjectLabel")
    [void]$sb.AppendLine("║  Generated : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
    [void]$sb.AppendLine("║  Root      : $ProjectPath")
    [void]$sb.AppendLine("║  Files     : $fileCount")
    [void]$sb.AppendLine("╚══════════════════════════════════════════════════════════════╝")
    [void]$sb.AppendLine()

    $index = 0
    foreach ($file in $allFiles) {
        $index++
        $relPath = Resolve-RelativePath -FullPath $file.FullName -RootPath $ProjectPath
        $sizeKB  = [Math]::Round($file.Length / 1KB, 1)

        Write-Progress -Activity "Dumping $ProjectLabel" -Status "($index/$fileCount) $relPath" -PercentComplete (($index / $fileCount) * 100)
        Write-Host "  [$index/$fileCount] $relPath ($sizeKB KB)" -ForegroundColor DarkGray

        [void]$sb.AppendLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        [void]$sb.AppendLine("FILE  : $relPath")
        [void]$sb.AppendLine("SIZE  : $sizeKB KB")
        [void]$sb.AppendLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        [void]$sb.AppendLine()

        $content = Get-FileContentSafe -FilePath $file.FullName
        [void]$sb.AppendLine($content)
        [void]$sb.AppendLine()
        [void]$sb.AppendLine()
    }

    Write-Progress -Activity "Dumping $ProjectLabel" -Completed

    # Ensure output dir exists
    if (-not (Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    }

    $sb.ToString() | Out-File -FilePath $OutputFile -Encoding UTF8 -Force

    $totalKB = [Math]::Round(((Get-Item $OutputFile).Length / 1KB), 1)
    Write-Host "`n  ✔ Done! → $OutputFile ($totalKB KB)`n" -ForegroundColor Green
}

# =====================================================================
#  EXECUTE — Generate one dump per project
# =====================================================================

Write-Host @"

  ╔═══════════════════════════════════════╗
  ║     CODE DUMP GENERATOR               ║
  ║     Flutter · React · .NET            ║
  ╚═══════════════════════════════════════╝

"@ -ForegroundColor Yellow

# --- Flutter ---
Export-ProjectCodeDump `
    -ProjectPath   $FlutterProjectPath `
    -ProjectLabel  "Flutter" `
    -ExcludeDirs   $FlutterExcludeDirs `
    -ExcludeFiles  $FlutterExcludeFiles `
    -IncludeExts   $FlutterIncludeExts `
    -OutputFile    (Join-Path $OutputDir "Flutter_Dump_$Timestamp.txt")


# --- React ---
Export-ProjectCodeDump `
    -ProjectPath   $ReactProjectPath `
    -ProjectLabel  "React" `
    -ExcludeDirs   $ReactExcludeDirs `
    -ExcludeFiles  $ReactExcludeFiles `
    -IncludeExts   $ReactIncludeExts `
    -OutputFile    (Join-Path $OutputDir "React_Dump_$Timestamp.txt")


# --- .NET ---
Export-ProjectCodeDump `
    -ProjectPath   $DotNetProjectPath `
    -ProjectLabel  ".NET" `
    -ExcludeDirs   $DotNetExcludeDirs `
    -ExcludeFiles  $DotNetExcludeFiles `
    -IncludeExts   $DotNetIncludeExts `
    -OutputFile    (Join-Path $OutputDir "DotNet_Dump_$Timestamp.txt")

    Export-ProjectCodeDump `
    -ProjectPath   $DotNetProjectPath1 `
    -ProjectLabel  ".NET" `
    -ExcludeDirs   $DotNetExcludeDirs `
    -ExcludeFiles  $DotNetExcludeFiles `
    -IncludeExts   $DotNetIncludeExts `
    -OutputFile    (Join-Path $OutputDir "DotNet_Dump1_$Timestamp.txt")

Write-Host @"

  ╔═══════════════════════════════════════╗
  ║     ALL DUMPS COMPLETE ✔              ║
  ║     Output folder: $OutputDir
  ╚═══════════════════════════════════════╝

"@ -ForegroundColor Yellow

<# TO GET A SPECIFIC SERVICE CODE
cd C:\MyGateApp

Get-ChildItem -Path src\Services\VisitorService -Recurse -Include *.cs | 
  Where-Object { $_.FullName -notlike "*\bin\*" -and $_.FullName -notlike "*\obj\*" -and $_.FullName -notlike "*Migrations*" } | 
  ForEach-Object { 
    Write-Host ("=" * 60)
    Write-Host "FILE: $($_.FullName)"
    Write-Host ("=" * 60)
    Get-Content $_.FullName
    Write-Host ""
  }
#>