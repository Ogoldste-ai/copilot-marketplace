<#
.SYNOPSIS
Build utilities for BMC module build automation.
Self-contained; shared helpers are intentionally duplicated in BmcModuleUtilities_clean.ps1.
#>

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
function Add-PathEntry {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PathEntry
    )

    if (-not (Test-Path -LiteralPath $PathEntry)) {
        return $false
    }

    $fullPath = [System.IO.Path]::GetFullPath($PathEntry).TrimEnd('\\')
    $pathEntries = @($env:Path -split ';' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

    foreach ($entry in $pathEntries) {
        $normalized = $entry.Trim().Trim('"').TrimEnd('\\')
        if ($normalized -ieq $fullPath) {
            return $false
        }
    }

    $env:Path = "$fullPath;$env:Path"
    return $true
}

function Test-CommandAvailable {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommandName
    )

    return [bool](Get-Command $CommandName -ErrorAction SilentlyContinue)
}

function Initialize-VsBuildEnvironment {
    if ((Test-Path variable:global:VsBuildEnvironmentInitialized) -and $global:VsBuildEnvironmentInitialized) {
        return
    }

    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    if (-not (Test-Path -LiteralPath $vswhere)) {
        Write-LogStep 'vswhere.exe not found. Continuing without VsDevCmd bootstrap.' -Level Warning
        $global:VsBuildEnvironmentInitialized = $true
        return
    }

    $installPath = & $vswhere -latest -products * -requires Microsoft.Component.MSBuild -property installationPath |
        Select-Object -First 1
    if ([string]::IsNullOrWhiteSpace($installPath)) {
        Write-LogStep 'Visual Studio installation path was not resolved by vswhere.' -Level Warning
        $global:VsBuildEnvironmentInitialized = $true
        return
    }

    $vsDevCmd = Join-Path $installPath 'Common7\Tools\VsDevCmd.bat'
    if (-not (Test-Path -LiteralPath $vsDevCmd)) {
        Write-LogStep "VsDevCmd.bat not found at expected path: $vsDevCmd" -Level Warning
        $global:VsBuildEnvironmentInitialized = $true
        return
    }

    Write-LogStep 'Importing Visual Studio developer environment...' -Level Info

    $cmdLine = '"{0}" -no_logo -arch=x86 -host_arch=x64 >nul & set' -f $vsDevCmd
    $envDump = & cmd.exe /d /s /c $cmdLine
    if ($LASTEXITCODE -ne 0 -or -not $envDump) {
        Write-LogStep 'Failed to import VsDevCmd environment. Continuing with current environment.' -Level Warning
        $global:VsBuildEnvironmentInitialized = $true
        return
    }

    foreach ($line in $envDump) {
        if ($line -notmatch '^[^=]+=') {
            continue
        }

        $name, $value = $line -split '=', 2
        if ([string]::IsNullOrWhiteSpace($name)) {
            continue
        }

        Set-Item -Path "env:$name" -Value $value
    }

    $global:VsBuildEnvironmentInitialized = $true
    Write-LogStep 'Visual Studio developer environment initialized' -Level Success
}

function Initialize-BuildToolchain {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleRoot
    )

    Initialize-VsBuildEnvironment

    $addedPaths = New-Object System.Collections.Generic.List[string]

    $candidatePaths = @(
        (Join-Path $env:USERPROFILE '.cargo\bin'),
        'C:\GCC_AARCH64\bin',
        'C:\Program Files (x86)\Arm GNU Toolchain arm-none-eabi\14.2 rel1\bin',
        'C:\Program Files (x86)\GNU Arm Embedded Toolchain\10 2021.10\bin',
        'C:\Keil_v5_41\ARM\ARMCLANG\bin'
    )

    foreach ($candidate in $candidatePaths) {
        if ([string]::IsNullOrWhiteSpace($candidate)) {
            continue
        }

        if (Add-PathEntry -PathEntry $candidate) {
            [void]$addedPaths.Add($candidate)
        }
    }

    if ($addedPaths.Count -gt 0) {
        Write-LogStep "Prepended toolchain paths: $($addedPaths -join '; ')" -Level Info
    }

    $mandatoryCommands = New-Object System.Collections.Generic.List[string]
    $recommendedCommands = New-Object System.Collections.Generic.List[string]

    if (Test-Path -LiteralPath (Join-Path $ModuleRoot 'rust_lib\rust_lib.vcxproj')) {
        [void]$mandatoryCommands.Add('cargo.exe')
    }

    if (Test-Path -LiteralPath (Join-Path $ModuleRoot 'core_a35')) {
        [void]$recommendedCommands.Add('aarch64-elf-gcc.exe')
        [void]$recommendedCommands.Add('aarch64-elf-objcopy.exe')
        [void]$recommendedCommands.Add('aarch64-elf-objdump.exe')
    }

    if (Test-Path -LiteralPath (Join-Path $ModuleRoot 'core_m7')) {
        [void]$recommendedCommands.Add('armclang.exe')
        [void]$recommendedCommands.Add('armlink.exe')
        [void]$recommendedCommands.Add('fromelf.exe')
    }

    $missingMandatory = @()
    foreach ($command in ($mandatoryCommands | Select-Object -Unique)) {
        if (-not (Test-CommandAvailable -CommandName $command)) {
            $missingMandatory += $command
        }
    }

    if ($missingMandatory.Count -gt 0) {
        Write-LogError "Missing required tool(s) in PATH: $($missingMandatory -join ', '). Install or add them to PATH, then re-run the task."
    }

    $missingRecommended = @()
    foreach ($command in ($recommendedCommands | Select-Object -Unique)) {
        if (-not (Test-CommandAvailable -CommandName $command)) {
            $missingRecommended += $command
        }
    }

    if ($missingRecommended.Count -gt 0) {
        Write-LogStep "Optional tool(s) were not found in PATH and may cause compile failures: $($missingRecommended -join ', ')" -Level Warning
    }
}

function Write-LogSection {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Header,

        [string]$BorderChar = '='
    )

    $border = $BorderChar * 50
    Write-Host ''
    Write-Host $border
    Write-Host $Header
    Write-Host $border
}

function Write-LogStep {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )

    $timestamp = Get-Date -Format 'HH:mm:ss'
    $colors = @{
        Info    = 'Gray'
        Warning = 'Yellow'
        Error   = 'Red'
        Success = 'Green'
    }

    Write-Host "[$timestamp]" -ForegroundColor Gray -NoNewline
    Write-Host " $Message" -ForegroundColor $colors[$Level]
}

function Write-LogSummary {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Summary,

        [string]$Title = 'Summary'
    )

    Write-LogSection $Title

    if ($Summary -is [hashtable]) {
        $items = $Summary.GetEnumerator() | Sort-Object Name
    } else {
        $items = $Summary.PSObject.Properties | Sort-Object Name
    }

    $maxKeyLength = ($items | ForEach-Object { $_.Name.Length } | Measure-Object -Maximum).Maximum
    foreach ($item in $items) {
        $padding = ' ' * ($maxKeyLength - $item.Name.Length)
        Write-Host "$($item.Name)$padding : $($item.Value)"
    }

    Write-Host ''
}

function Write-LogError {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [int]$ExitCode = 1
    )

    Write-Host ''
    Write-Host "[ERROR] $Message" -ForegroundColor Red
    Write-Host ''
    exit $ExitCode
}

function Get-BmcModuleRoot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$WorkspaceFolder,

        [Parameter(Mandatory = $true)]
        [string]$ModuleName,

        [ValidateSet('BMC')]
        [string]$TargetRoot = 'BMC'
    )

    $normalizedWorkspace = [System.IO.Path]::GetFullPath($WorkspaceFolder)

    if ($ModuleName -match '^BMC\\Modules\\(.+)$') {
        $qualifiedPath = Join-Path $normalizedWorkspace "Modules\$($Matches[1])"
        if (Test-Path -LiteralPath $qualifiedPath) {
            return [System.IO.Path]::GetFullPath($qualifiedPath)
        }

        Write-LogError "Qualified module path does not exist: $qualifiedPath"
    }

    $candidateDirs = @(
        (Join-Path $normalizedWorkspace "Modules\$ModuleName"),
        (Join-Path $normalizedWorkspace $ModuleName)
    )

    $moduleDir = $candidateDirs | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if (-not $moduleDir) {
        Write-LogError "Module directory not found for '$ModuleName'. Searched: $($candidateDirs -join ', ')"
    }

    return [System.IO.Path]::GetFullPath($moduleDir)
}

function Get-SolutionPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleRoot
    )

    $solution = Get-ChildItem -LiteralPath $ModuleRoot -Filter *.sln -File -ErrorAction SilentlyContinue |
        Sort-Object Name |
        Select-Object -First 1

    if (-not $solution) {
        Write-LogError "No solution file found under: $ModuleRoot"
    }

    return $solution.FullName
}

function Get-SolutionConfigurations {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SolutionPath
    )

    $configs = New-Object System.Collections.Generic.List[string]
    $inSection = $false

    foreach ($line in Get-Content -LiteralPath $SolutionPath) {
        if ($line -match '^\s*GlobalSection\(SolutionConfigurationPlatforms\)') {
            $inSection = $true
            continue
        }

        if ($inSection -and $line -match '^\s*EndGlobalSection') {
            break
        }

        if ($inSection -and $line -match '^\s*([^=|]+)\|Win32\s*=') {
            $configName = $Matches[1].Trim()
            if (-not $configs.Contains($configName)) {
                [void]$configs.Add($configName)
            }
        }
    }

    return $configs.ToArray()
}

function Get-HostExePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleRoot
    )

    $candidates = @(
        (Join-Path $ModuleRoot 'host\Debug\Host.exe'),
        (Join-Path $ModuleRoot 'host\Release\Host.exe')
    )

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return [System.IO.Path]::GetFullPath($candidate)
        }
    }

    $fallback = Get-ChildItem -LiteralPath (Join-Path $ModuleRoot 'host') -Recurse -Filter Host.exe -File -ErrorAction SilentlyContinue |
        Sort-Object FullName |
        Select-Object -First 1

    if ($fallback) {
        return $fallback.FullName
    }

    return $null
}

function Get-BuildArtifacts {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleRoot
    )

    return Get-ChildItem -LiteralPath $ModuleRoot -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object {
            ($_.Name -ieq 'Host.exe') -or
            ($_.Extension -in '.bin', '.elf', '.axf', '.map') -or
            ($_.Name -like '*.map.txt')
        } |
        Where-Object {
            $_.FullName -match '\\(host|core_[^\\]+|rust_lib)\\'
        } |
        Sort-Object FullName
}

function Get-MsBuildPath {
    if (-not (Test-Path variable:global:CachedBmcMsBuildPath) -or [string]::IsNullOrWhiteSpace($global:CachedBmcMsBuildPath)) {
        Write-LogStep 'Locating MSBuild.exe...' -Level Info

        $msbuildPath = $null
        $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
        if (Test-Path -LiteralPath $vswhere) {
            $msbuildPath = & $vswhere -latest -products * -requires Microsoft.Component.MSBuild -find 'MSBuild\**\Bin\MSBuild.exe' |
                Select-Object -First 1
        }

        if (-not $msbuildPath) {
            $fallbacks = @(
                "$env:ProgramFiles\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe",
                "$env:ProgramFiles\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe",
                "$env:ProgramFiles\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe"
            )

            foreach ($candidate in $fallbacks) {
                if (Test-Path -LiteralPath $candidate) {
                    $msbuildPath = $candidate
                    break
                }
            }
        }

        if (-not $msbuildPath) {
            Write-LogError 'MSBuild.exe was not found in any known location.' -ExitCode 2
        }

        $global:CachedBmcMsBuildPath = $msbuildPath
        Write-LogStep "Using MSBuild at: $msbuildPath" -Level Success
    }

    return $global:CachedBmcMsBuildPath
}

function Invoke-MsBuild {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,

        [Parameter(Mandatory = $true)]
        [string]$Configuration,

        [string]$Platform = 'Win32',

        [string]$SolutionDirectory
    )

    if (-not (Test-Path -LiteralPath $TargetPath)) {
        Write-LogError "Build target not found: $TargetPath"
    }

    $msbuildPath = Get-MsBuildPath
    $targetName = Split-Path -Leaf $TargetPath

    Write-LogStep "Building: $targetName | Config: $Configuration | Platform: $Platform" -Level Info

    $commonArgs = @(
        $TargetPath,
        '/m',
        "/p:Configuration=$Configuration",
        "/p:Platform=$Platform",
        '/verbosity:minimal'
    )

    if (-not [string]::IsNullOrWhiteSpace($SolutionDirectory)) {
        $normalized = [System.IO.Path]::GetFullPath($SolutionDirectory)
        if (-not $normalized.EndsWith('\')) {
            $normalized = "$normalized\"
        }
        $commonArgs += "/p:SolutionDir=$normalized"
    }

    # Clean + Rebuild is required: the pre-build step deletes objs.txt, which is only
    # regenerated by compiling, so an incremental Build leaves the link step without it.
    foreach ($target in @('Clean', 'Rebuild')) {
        Write-LogStep "MSBuild target: $target" -Level Info
        & $msbuildPath @commonArgs "/t:$target"
        if ($LASTEXITCODE -ne 0) {
            Write-LogError "MSBuild $target failed with exit code $LASTEXITCODE" -ExitCode $LASTEXITCODE
        }
    }

    Write-LogStep "Build succeeded: $targetName" -Level Success
}
