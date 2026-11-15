<#
.SYNOPSIS
Artifact-clearing utilities for BMC module build automation.
Self-contained; shared helpers are intentionally duplicated in BmcModuleUtilities_buildall.ps1.
#>

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

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

function Clear-ModuleArtifacts {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleRoot
    )

    $pathsToRemove = New-Object System.Collections.Generic.List[string]

    $hostRoot = Join-Path $ModuleRoot 'host'
    if (Test-Path -LiteralPath $hostRoot) {
        foreach ($dir in @('Debug', 'Release')) {
            $candidate = Join-Path $hostRoot $dir
            if (Test-Path -LiteralPath $candidate) {
                [void]$pathsToRemove.Add($candidate)
            }
        }
    }

    $coreDirs = Get-ChildItem -LiteralPath $ModuleRoot -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like 'core_*' }
    foreach ($coreDir in $coreDirs) {
        foreach ($dir in @('Debug', 'Release')) {
            $candidate = Join-Path $coreDir.FullName $dir
            if (Test-Path -LiteralPath $candidate) {
                [void]$pathsToRemove.Add($candidate)
            }
        }

        foreach ($fileName in @('objs.txt', 'OBJS.txt')) {
            $fileCandidate = Join-Path $coreDir.FullName $fileName
            if (Test-Path -LiteralPath $fileCandidate) {
                [void]$pathsToRemove.Add($fileCandidate)
            }
        }
    }

    $moduleObjFiles = @(
        (Join-Path $ModuleRoot 'objs.txt'),
        (Join-Path $ModuleRoot 'OBJS.txt'),
        (Join-Path $ModuleRoot 'rust_lib\target')
    )
    foreach ($path in $moduleObjFiles) {
        if (Test-Path -LiteralPath $path) {
            [void]$pathsToRemove.Add($path)
        }
    }

    $removedCount = 0
    foreach ($path in $pathsToRemove | Select-Object -Unique) {
        Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue
        Write-LogStep "Removed: $path" -Level Info
        $removedCount++
    }

    if ($removedCount -eq 0) {
        Write-LogStep 'No artifacts found to remove' -Level Info
    } else {
        Write-LogStep "Removed $removedCount artifact(s)" -Level Success
    }
}
