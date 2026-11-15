---
name: local-clearing-bmc-module-artifacts
description: Use when asked to clean one BMC solution or remove one BMC module's build artifacts in ec_accurev_git without rebuilding.
---

# Clear one BMC module's build artifacts

Trigger phrase: "clean a BMC solution"

## Purpose

Remove build outputs from one named `BMC\Modules\<module>` using the
repository's `BMC\.vscode\BmcModuleTask.ps1 -Action ClearArtifacts`,
then remove that module's `.vs` directory. This does not rebuild or
remove shared outputs outside the module.

## Assistant workflow

1. Follow `ec_accurev_git\BMC\AGENTS.md`. Resolve the exact named
   module under `BMC\Modules` and confirm it contains a `.sln`; ask
   which module if unspecified. Do not substitute `CleanAllModules`
   (cleans and rebuilds) or `ClearAllArtifacts` (affects every module).
2. Read `Clear-ModuleArtifacts` in
   `BmcModuleUtilities_clean.ps1` (in this skill's folder) before running it. Enumerate
   the **existing** paths it will remove: `host\Debug`,
   `host\Release`, each `core_*\Debug`, `core_*\Release`,
   `core_*\objs.txt`/`OBJS.txt`, module-root `objs.txt`/`OBJS.txt`,
   and `rust_lib\target`. Also inspect the exact module-local `.vs`
   directory, including hidden/ignored contents; it may contain `.suo`
   and layout files holding Visual Studio user state. Check
   `git status --short` and inspect all deletion targets for user data.
   Stop if `.vs` is a symlink/junction or targets contain unexpected
   files.
3. Show the module, exact paths to be deleted (including `.vs` and its
   user settings if present), and both commands; obtain
   explicit approval **for this cleanup** before running it. A request
   to create or review this skill is not approval to delete artifacts.
4. From the `ec_accurev_git` root, run this PowerShell command with
   the approved module name (example):

   ```powershell
   & .\BMC\.vscode\BmcModuleTask.ps1 -Action ClearArtifacts -WorkspaceFolder (Resolve-Path .\BMC).Path -Module BMC_template
   if ($LASTEXITCODE -ne 0) { throw "ClearArtifacts failed: $LASTEXITCODE" }
   ```

5. Check the task exit code and independently check that every
   `ClearArtifacts` target from step 2 is absent; its `Remove-Item`
   suppresses deletion errors, so "Cleanup complete" is not proof.
   If any target remains, stop and report the failure.
6. Remove only the approved module-local `.vs` directory with
   `Remove-Item -LiteralPath $vsDir -Recurse -Force -ErrorAction Stop`,
   if present. Verify `.vs` is absent and check `git status --short`
   for unintended source changes. Report any remaining outputs outside
   these targets (such as a nonempty module-root `Release` directory);
   do not silently broaden deletion or claim every artifact is gone.

## Manual bash workflow

On the Windows build machine, start PowerShell from Bash:

```bash
pwsh.exe -NoProfile
```

Opens an interactive PowerShell session. Run the following commands
**inside that session**, not in Bash:

```powershell
Set-Location 'C:\CCSystem\ec_accurev_git'
$module = Join-Path (Resolve-Path '.\BMC\Modules').Path 'BMC_template'
$targets = @('host\Debug', 'host\Release', 'objs.txt', 'OBJS.txt', 'rust_lib\target') |
    ForEach-Object { Join-Path $module $_ }
foreach ($core in Get-ChildItem -LiteralPath $module -Directory -Filter 'core_*') {
    $targets += @('Debug', 'Release', 'objs.txt', 'OBJS.txt') |
        ForEach-Object { Join-Path $core.FullName $_ }
}
$targets | Where-Object { Test-Path -LiteralPath $_ }
$vsDir = Join-Path $module '.vs'
if (Test-Path -LiteralPath $vsDir) {
    $vsItem = Get-Item -LiteralPath $vsDir -Force
    if ($vsItem.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw '.vs is a link; stop' }
    Get-ChildItem -LiteralPath $vsDir -Recurse -File -Force |
        Select-Object -ExpandProperty FullName
}
git status --short --ignored --untracked-files=all -- BMC\Modules\BMC_template
```

Selects the module, lists existing removal targets and every `.vs`
file, and shows tracked, untracked, and ignored files. Inspect those
targets for files you need to keep before approving deletion, including
`.suo` and layout files; `git status` does not list unchanged tracked
files.

```powershell
& .\BMC\.vscode\BmcModuleTask.ps1 -Action ClearArtifacts -WorkspaceFolder (Resolve-Path .\BMC).Path -Module BMC_template
if ($LASTEXITCODE -ne 0) { throw "ClearArtifacts failed: $LASTEXITCODE" }
```

Deletes the approved module's supported build output paths without
rebuilding. Run only after reviewing and approving all targets.

```powershell
$leftovers = @($targets | Where-Object { Test-Path -LiteralPath $_ })
if ($leftovers.Count) { $leftovers; throw 'Artifact cleanup incomplete' }
if (Test-Path -LiteralPath $vsDir) {
    if ((Get-Item -LiteralPath $vsDir -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) {
        throw '.vs is a link; stop'
    }
    Remove-Item -LiteralPath $vsDir -Recurse -Force -ErrorAction Stop
}
if (Test-Path -LiteralPath $vsDir) { throw 'Visual Studio cache cleanup incomplete' }
git status --short -- BMC\Modules\BMC_template
```

Stops if the task left artifacts behind; otherwise removes the
approved `.vs` directory and checks that it is gone, then shows source
changes. For another module, change both `BMC_template` values above.

## Notes / approval

`ClearArtifacts` does not remove `.vs` itself. Removing `.vs` also
discards Visual Studio workspace settings stored there; keep it if
approval does not include that effect. Do not clean other modules,
rebuild, commit, or publish a skill as part of this operation.
