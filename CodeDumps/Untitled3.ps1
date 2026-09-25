<#
.SYNOPSIS
    Dumps all source code files into split text files per project type.
    Each output part file stays under a configurable size limit (default 150 KB).
.USAGE
    1. Set the 3 project root paths below.
    2. Run:  .\Generate-CodeDump.ps1
    3. Output files appear in $OutputDir, split into _Part1.txt, _Part2.txt, …
#>

# =====================================================================
#  CONFIGURATION
# =====================================================================


 $FlutterProjectPath  = "C:\MyGateApp\mygate_app"
 $ReactProjectPath    = "C:\MyGateApp\src\Client"
 $DotNetProjectPath   = "C:\MyGateApp\src\Services"
  $DotNetProjectPath1   = "C:\MyGateApp\src\BuildingBlocks"

 $OutputDir           = "C:\MyGateApp\CodeDumps"   # Where dump files land
 $Timestamp           = Get-Date -Format "yyyyMMdd_HHmmss"

# --- Split threshold ---
 $MaxDumpFileSizeKB   = 150
 $MaxDumpFileSizeBytes = $MaxDumpFileSizeKB * 1KB

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
    ".fvm", "windows\flutter\ephemeral",
    "linux\flutter\ephemeral", "macos\Flutter\ephemeral",
    "web\icons", ".git"
)
 $FlutterExcludeFiles = @(
    "*.lock", "*.g.dart", "*.freezed.dart", "*.config",
    "*.abi.json", "*.symlink", "*.stamp",
    "*.png", "*.jpg", "*.jpeg", "*.gif", "*.svg", "*.ico",
    "*.woff", "*.woff2", "*.ttf", "*.eot", "*.otf"
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
        $pattern = $excl.Split("\")[-1]
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
    if ([System.IO.Path]::GetFileName($FileName).StartsWith(".")) {
        $fullName = [System.IO.Path]::GetFileName($FileName).ToLower()
        foreach ($inc in $IncludeExts) {
            if ($fullName -like $inc.TrimStart("*")) { return $true }
        }
    }
    return $IncludeExts -contains $ext
}

 $MaxFileReadBytes = 1MB

function Get-FileContentSafe {
    param([string]$FilePath)
    try {
        $len = (Get-Item $FilePath).Length
        if ($len -gt $MaxFileReadBytes) {
            return "[SKIPPED: File exceeds 1 MB ($len bytes)]"
        }
        $bytes = [System.IO.File]::ReadAllBytes($FilePath)
        $checkLen = [Math]::Min($bytes.Length, 8192)
        $nullCount = 0
        for ($i = 0; $i -lt $checkLen; $i++) {
            if ($bytes[$i] -eq 0) { $nullCount++ }
        }
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
#  CORE DUMP FUNCTION  — with auto-split
# =====================================================================

function Export-ProjectCodeDump {
    param(
        [string]$ProjectPath,
        [string]$ProjectLabel,
        [string[]]$ExcludeDirs,
        [string[]]$ExcludeFiles,
        [string[]]$IncludeExts,
        [string]$OutputFilePrefix      # e.g. "Flutter_Dump_20250712_143001"
    )

    if (-not (Test-Path $ProjectPath)) {
        Write-Warning "[$ProjectLabel] Path not found: $ProjectPath — skipping."
        return
    }

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  Scanning : $ProjectLabel" -ForegroundColor Cyan
    Write-Host "  Root     : $ProjectPath" -ForegroundColor Cyan
    Write-Host "  Max part : $MaxDumpFileSizeKB KB" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    # -----------------------------------------------------------------
    #  Collect files (with the fixed split)
    # -----------------------------------------------------------------
    $allFiles = Get-ChildItem -Path $ProjectPath -File -Recurse -ErrorAction SilentlyContinue | Where-Object {
        $file = $_
        $relativePath = Resolve-RelativePath -FullPath $file.FullName -RootPath $ProjectPath

        # Directory exclusion — fixed: use -split with regex
        $dirParts = $relativePath -split '[\\/]'
        $dirExcluded = $false
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

        if (Test-ShouldExcludeFile -FileName $file.Name -ExcludeFiles $ExcludeFiles) { return $false }
        if (-not (Test-ShouldIncludeFile -FileName $file.Name -IncludeExts $IncludeExts)) { return $false }

        return $true
    }

    $allFiles = $allFiles | Sort-Object FullName
    $fileCount = $allFiles.Count
    Write-Host "  Found $fileCount files to dump." -ForegroundColor Green

    if ($fileCount -eq 0) {
        Write-Warning "[$ProjectLabel] No files matched — nothing to dump."
        return
    }

    # Ensure output dir
    if (-not (Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    }

    # -----------------------------------------------------------------
    #  Write with auto-split
    # -----------------------------------------------------------------
    $separator = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    $encoding  = [System.Text.Encoding]::UTF8

    $partNumber         = 1
    $entriesInCurrentPart = 0
    $partFilePath       = Join-Path $OutputDir "${OutputFilePrefix}_Part${partNumber}.txt"
    $writer             = [System.IO.StreamWriter]::new($partFilePath, $false, $encoding)
    $bytesWritten       = 0

    # Project header for Part 1
    $header = @"
╔══════════════════════════════════════════════════════════════╗
║  CODE DUMP — $ProjectLabel
║  Generated : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
║  Root      : $ProjectPath
║  Files     : $fileCount
║  Max part  : ${MaxDumpFileSizeKB} KB
╚══════════════════════════════════════════════════════════════╝

"@
    $writer.Write($header)
    $bytesWritten += $encoding.GetByteCount($header)

    $index = 0
    foreach ($file in $allFiles) {
        $index++
        $relPath = Resolve-RelativePath -FullPath $file.FullName -RootPath $ProjectPath
        $sizeKB  = [Math]::Round($file.Length / 1KB, 1)

        Write-Progress -Activity "Dumping $ProjectLabel" `
                       -Status "($index/$fileCount) Part $partNumber — $relPath" `
                       -PercentComplete (($index / $fileCount) * 100)
        Write-Host "  [$index/$fileCount] $relPath ($sizeKB KB)" -ForegroundColor DarkGray

        # Build this file's entry
        $content = Get-FileContentSafe -FilePath $file.FullName

        $entry = @"
 $separator
FILE  : $relPath
SIZE  : $sizeKB KB
 $separator

 $content


"@
        $entryBytes = $encoding.GetByteCount($entry)

        # ── SPLIT CHECK ─────────────────────────────────────────────
        # If adding this entry would exceed the limit AND we've already
        # written at least one file entry in the current part → rotate.
        # (A single oversize entry still gets written — it just becomes
        #  the sole occupant of its part, and the next entry starts a
        #  new part.)
        if (($bytesWritten + $entryBytes) -gt $MaxDumpFileSizeBytes -and $entriesInCurrentPart -gt 0) {

            # Close current part
            $writer.Close()
            $writer.Dispose()
            $partKB = [Math]::Round(($bytesWritten / 1KB), 1)
            Write-Host "    ✂ Part $partNumber closed at $partKB KB — rotating" -ForegroundColor Yellow

            # Open next part
            $partNumber++
            $partFilePath = Join-Path $OutputDir "${OutputFilePrefix}_Part${partNumber}.txt"
            $writer       = [System.IO.StreamWriter]::new($partFilePath, $false, $encoding)
            $bytesWritten = 0
            $entriesInCurrentPart = 0

            # Continuation header
            $contHeader = @"
╔══════════════════════════════════════════════════════════════╗
║  CODE DUMP — $ProjectLabel  (continued — Part $partNumber)
║  Generated : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
║  Root      : $ProjectPath
║  Max part  : ${MaxDumpFileSizeKB} KB
╚══════════════════════════════════════════════════════════════╝

"@
            $writer.Write($contHeader)
            $bytesWritten += $encoding.GetByteCount($contHeader)
        }

        # Write entry
        $writer.Write($entry)
        $bytesWritten += $entryBytes
        $entriesInCurrentPart++
    }

    Write-Progress -Activity "Dumping $ProjectLabel" -Completed

    # Close final part
    $writer.Close()
    $writer.Dispose()
    $finalPartKB = [Math]::Round(($bytesWritten / 1KB), 1)
    Write-Host "    ✔ Part $partNumber closed at $finalPartKB KB" -ForegroundColor DarkGreen

    Write-Host "`n  ✔ Done! → $partNumber part(s) written to $OutputDir\${OutputFilePrefix}_Part*.txt`n" -ForegroundColor Green
}

# =====================================================================
#  EXECUTE
# =====================================================================

Write-Host @"

  ╔═══════════════════════════════════════╗
  ║     CODE DUMP GENERATOR               ║
  ║     Flutter · React · .NET            ║
  ║     Auto-split at $MaxDumpFileSizeKB KB per file     ║
  ╚═══════════════════════════════════════╝

"@ -ForegroundColor Yellow

# --- Flutter ---
Export-ProjectCodeDump `
    -ProjectPath     $FlutterProjectPath `
    -ProjectLabel    "Flutter" `
    -ExcludeDirs     $FlutterExcludeDirs `
    -ExcludeFiles    $FlutterExcludeFiles `
    -IncludeExts     $FlutterIncludeExts `
    -OutputFilePrefix "Flutter_Dump_$Timestamp"

# --- React ---
Export-ProjectCodeDump `
    -ProjectPath     $ReactProjectPath `
    -ProjectLabel    "React" `
    -ExcludeDirs     $ReactExcludeDirs `
    -ExcludeFiles    $ReactExcludeFiles `
    -IncludeExts     $ReactIncludeExts `
    -OutputFilePrefix "React_Dump_$Timestamp"

# --- .NET ---
Export-ProjectCodeDump `
    -ProjectPath     $DotNetProjectPath `
    -ProjectLabel    ".NET" `
    -ExcludeDirs     $DotNetExcludeDirs `
    -ExcludeFiles    $DotNetExcludeFiles `
    -IncludeExts     $DotNetIncludeExts `
    -OutputFilePrefix "DotNet_Dump_$Timestamp"

    Export-ProjectCodeDump `
    -ProjectPath   $DotNetProjectPath1 `
    -ProjectLabel  ".NET" `
    -ExcludeDirs   $DotNetExcludeDirs `
    -ExcludeFiles  $DotNetExcludeFiles `
    -IncludeExts   $DotNetIncludeExts `
    -OutputFile    "DotNet_Dump1_$Timestamp

Write-Host @"

  ╔═══════════════════════════════════════╗
  ║     ALL DUMPS COMPLETE ✔              ║
  ║     Output folder: $OutputDir
  ╚═══════════════════════════════════════╝

"@ -ForegroundColor Yellow