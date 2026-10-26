---
name: local-building-bmc-modules
description: Use when compiling a BMC module or BMC_template in ec_accurev_git with a Release, A35_Release, M7_Release, MCU_Release, or CPTRA_Release solution configuration.
---

# Build BMC modules in ec_accurev_git

Trigger phrase: "compile a BMC module"

## Purpose

Compile one `BMC\Modules\<module>` solution through the repository's
`BMC\.vscode\BmcModuleTask.ps1`, not by calling MSBuild directly. This
builds the projects selected by that solution configuration; it does not
run tests.

## Assistant workflow

1. Follow `ec_accurev_git\BMC\AGENTS.md`. Identify the exact module
   directory and requested configuration; do not guess either. Check that
   the module has a `.sln` and that its
   `SolutionConfigurationPlatforms` section defines the configuration.
   The task accepts `Release`, `A35_Release`, `M7_Release`,
   `MCU_Release`, and `CPTRA_Release`, but individual solutions may
   support fewer.
2. Check `git status --short` inside `ec_accurev_git` before building.
   Do not overwrite unrelated work. Warn and get explicit approval for
   `A35_Release`: the task calls `Clear-ModuleArtifacts` before that
   build. Do not substitute `CleanAllModules`, `ClearArtifacts`, or
   `ClearAllArtifacts` for a requested build.
3. From the `ec_accurev_git` root, run the task in PowerShell, keeping
   its output and capturing `$LASTEXITCODE` immediately:

   ```powershell
   & .\BMC\.vscode\BmcModuleTask.ps1 -Action BuildModuleConfiguration -WorkspaceFolder (Resolve-Path .\BMC).Path -Module BMC_template -Configuration Release
   ```

   Substitute the actual module directory name and supported configuration.
   The task locates MSBuild and initializes the toolchains itself.
4. Check for exit status 0 and the `Build Complete` summary. Verify the expected
   nonempty outputs for the selected projects were produced during this build,
   or that the build log explicitly reports those targets up to date;
   do not treat a nonzero artifact count or an old `Host.exe` as proof
   that every target compiled. For `BMC_template` `Release`, the host is
   `host\Debug\Host.exe` (not `host\Release\Host.exe`); core images are
   under their `core_*\Release` directories. Check `git status --short`
   again to identify any generated tracked changes. Report failures and
   missing outputs, without claiming success or retrying silently.

## Manual bash workflow

From a Bash terminal on the Windows build machine:

```bash
pwsh.exe -NoProfile -Command 'Set-Location "C:\CCSystem\ec_accurev_git"; git status --short; if (-not (Select-String -Path ".\BMC\Modules\BMC_template\BMC_Template.sln" -Pattern "^\s*Release\|Win32\s*=" -Quiet -ErrorAction Stop)) { throw "Release|Win32 is not defined" }'
```

Opens PowerShell at the checkout, displays existing changes, and checks for
the solution's Release configuration. Replace the checkout path, module,
solution name, and configuration as needed. Stop if the check fails or
there are unexpected changes.

```bash
pwsh.exe -NoProfile -Command 'Set-Location "C:\CCSystem\ec_accurev_git"; & ".\BMC\.vscode\BmcModuleTask.ps1" -Action BuildModuleConfiguration -WorkspaceFolder (Resolve-Path ".\BMC").Path -Module BMC_template -Configuration Release; exit $LASTEXITCODE'
```

Builds the template through the repository task. The final `exit`
propagates the build's exit code to Bash; note the start time to
distinguish fresh outputs from previous builds.

```bash
pwsh.exe -NoProfile -Command 'Set-Location "C:\CCSystem\ec_accurev_git"; Get-Item -ErrorAction Stop ".\BMC\Modules\BMC_template\host\Debug\Host.exe", ".\BMC\Modules\BMC_template\core_a35\Release\core_a35.bin", ".\BMC\Modules\BMC_template\core_m7\Release\core_m7.bin", ".\BMC\Modules\BMC_template\core_mcu_riscv\Release\core_mcu_riscv.bin", ".\BMC\Modules\BMC_template\core_cptra_riscv\Release\core_cptra_riscv.bin" | Select-Object FullName,Length,LastWriteTime; git status --short'
```

Displays the host and four core image sizes and timestamps, then shows
any tracked changes after the build. Confirm the outputs are nonempty
and recent; for other configurations, inspect the solution's selected
projects rather than assuming all four core images will be generated.

## Notes / approval

`A35_Release` clears module artifacts before building; confirm that
effect before running it. Creating or reviewing this skill is not
approval to run a build. Keep compilation separate from test execution,
commits, and marketplace publication.
