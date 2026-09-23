---
name: shared-skill-ssh-command
description: Run a command on a specific server over SSH and interpret the result, separating SSH transport failures from remote command failures.
---

# Run a command over SSH

Trigger phrase: "ssh command"

## Purpose

Run a command on a specific server over SSH and interpret the result. Resolve the target
from the saved SSH config instead of guessing, run the command non-interactively so it can
never hang on a prompt, capture stdout, stderr, and the exit code separately, and then
explain what happened — in particular whether SSH itself failed or the remote command failed.

## Assistant workflow

1. Resolve the target machine. Never guess it.
   - List the saved aliases with `grep -E '^Host ' ~/.ssh/config`.
   - If the user names a machine that has no alias yet, hand off to the
     "connect to machine" skill first.
   - If there are no keys at all, hand off to the "create ssh key" skill first.
2. Confirm the exact command that will run on the remote machine before running it.
   Show it to the user verbatim.
3. Refuse to proceed without explicit confirmation for destructive commands: `rm`, `kill`,
   `pkill`, `reboot`, `shutdown`, `dd`, `mkfs`, `chmod -R`, `chown -R`, and any redirection
   that overwrites an existing file.
4. Run the command non-interactively, capturing stdout, stderr, and the exit code as three
   separate results. Never merge the streams.
5. Pass the remote command after `--` and single-quoted so the local shell cannot expand or
   rewrite it before it is sent.
6. Wrap long-running commands in `timeout <N>` so a hung remote command cannot block the
   session.
7. Report the exact command sent, the exit code, stdout, and stderr — verbatim. If a stream
   is empty, say so explicitly rather than implying success.
8. Interpret the exit code using the table below, and separate an SSH transport failure from
   a remote command failure. Exit code `255` means SSH itself failed and the remote command
   never ran at all.
9. If the exit code is `255`, match the stderr text against the stderr table below and give
   the matching fix.
10. Finish with a one-line plain-language verdict and one concrete next step.

## Exit code reference

| Code | Meaning | Suggested next step |
|------|---------|---------------------|
| `0` | Success | Nothing to do |
| `1`-`125` | The remote command ran and failed | Read stderr; it is a real remote error |
| `124` | `timeout` killed the command | Raise the timeout or run it detached |
| `126` | Found but not executable | Check the file's permission bits |
| `127` | Command not found | Check `PATH` or where the tool is installed remotely |
| `130` | Interrupted (SIGINT) | Re-run if it was accidental |
| `137` | Killed (SIGKILL), often the OOM killer | Check memory on the remote machine |
| `255` | SSH transport failure - the command never ran | See the stderr table below |

## SSH failure (exit 255) stderr reference

| stderr contains | Cause | Fix |
|-----------------|-------|-----|
| `Permission denied (publickey)` | The key is not authorized on the machine | Re-run the "connect to machine" skill |
| `Host key verification failed` | Host key changed or is unknown | Verify the host is genuine, then update `known_hosts` |
| `Could not resolve hostname` | DNS failure or a typo in the alias | Check the alias and its `HostName` |
| `Connection timed out` / `No route to host` | Network unreachable or host down | Check the VPN and whether the host is up |
| `Connection refused` | No sshd listening on that port | Check the remote SSH service and port |

## Manual bash workflow

```bash
grep -E '^Host ' ~/.ssh/config
```
Lists the connection aliases you have already saved, so you can pick the right server
instead of typing a raw user and hostname.

```bash
ssh -o BatchMode=yes -o ConnectTimeout=10 <alias> -- 'true'
```
Checks that the alias still connects before you send a real command. `BatchMode=yes` makes
SSH fail immediately instead of stopping at a password prompt, and `ConnectTimeout=10` stops
it hanging on an unreachable host.

```bash
ssh -o BatchMode=yes -o ConnectTimeout=10 <alias> -- '<command>'
```
Runs your command on the remote machine. Everything after `--` is sent to the remote shell,
and single quotes stop your local shell from expanding it first.

```bash
out=$(ssh -o BatchMode=yes -o ConnectTimeout=10 <alias> -- '<command>' 2>/tmp/ssh_err); rc=$?
printf 'exit=%s\n--- stdout ---\n%s\n--- stderr ---\n' "$rc" "$out"; cat /tmp/ssh_err
```
Captures the three results separately: stdout into a variable, stderr into a file, and the
exit code into `rc`. Keeping them apart is what lets you tell a real remote error from
ordinary output.

```bash
ssh -o BatchMode=yes -o ConnectTimeout=10 <alias> -- 'timeout 30 <command>'
```
Runs the command with a 30 second limit on the remote side. If it is still running when the
limit is reached it is killed and you get exit code `124`.

```bash
ssh -o BatchMode=yes -o ConnectTimeout=10 -v <alias> -- 'true' 2>&1 | tail -n 20
```
Shows SSH's own negotiation output. Use this only when you get exit code `255` and need to
see which stage of the connection failed.

## Notes / approval

Use this skill when the user wants to run something on a remote machine and understand the
result. Always resolve the server from the saved SSH config and confirm the command before
running it. Always keep stdout, stderr, and the exit code separate, and report them verbatim
rather than paraphrasing.

Never echo, log, or store a password. With `BatchMode=yes` a password prompt should never
appear; if authentication fails, that is the signal to run the "connect to machine" skill,
not to ask for a password here.

This skill deliberately does not handle `sudo`. An interactive `sudo` password prompt cannot
work under `BatchMode`, so if the user needs `sudo`, say so and stop instead of hanging.

Keep this skill generic. Interpret SSH and shell level results only - project specific
meaning for a command's output belongs in the agent or skill that owns that domain.
