---
name: shared-skill-ssh-connect-to-machine
description: Connect to a machine with a chosen key, prompt for the password only if needed, then save the connection to the SSH config.
---

# Connect to machine over SSH

Trigger phrase: "connect to machine"

## Purpose

Connect to a remote machine as `<user>` using an SSH key the user selects from a
list. If the key is not yet authorized on the machine, ask for the remote password,
install the key so future logins are passwordless, and once the connection works,
save it to `~/.ssh/config` under a Host alias the user chooses.

## Assistant workflow

1. Confirm the `<user name>` and `<machine name>`. Ask for either if it is missing.
2. Show the available keys to use and let the user pick one:
   - list public keys with `ls -l ~/.ssh/*.pub`
   - show each fingerprint with `ssh-keygen -lf <key>.pub`
   - if there are no keys, stop and suggest creating one first (see the "create ssh key" skill).
3. Test whether the chosen key already works, without hanging on a prompt:
   `ssh -o IdentitiesOnly=yes -o BatchMode=yes -i ~/.ssh/<key> <user>@<machine> true`.
   - If this succeeds, the key is already authorized — skip to step 6.
4. If it needs a password, ask the user for the remote account password. Treat it as a
   secret: do not echo it, log it, put it in a command's arguments, or store it in any file.
5. Install the chosen key with `ssh-copy-id` using the password only for this one step, then
   confirm the machine now accepts the key. Provide the password through an environment
   variable or a temporary file (for example `sshpass -e` / `sshpass -f`), never through
   `-p` on the command line, and clear it immediately afterwards.
6. Verify the connection works without a password:
   `ssh -o IdentitiesOnly=yes -o BatchMode=yes -i ~/.ssh/<key> <user>@<machine> true`.
7. On success, ask the user for the `Host` alias name to save the connection under.
8. Add the connection to `~/.ssh/config`:
   - create `~/.ssh/config` with safe permissions first if it does not exist
   - skip if a `Host` entry with that alias already exists; otherwise append an entry with
     `HostName`, `User`, a full-path `IdentityFile`, and `IdentitiesOnly yes`.
9. Test the saved alias with `ssh <alias> true` and report the result.

## Manual bash workflow

```bash
ls -l ~/.ssh/*.pub
```
Lists the public keys you can choose from.

```bash
ssh-keygen -lf ~/.ssh/<key>.pub
```
Shows the fingerprint of a key so you can confirm which one to use.

```bash
ssh -o IdentitiesOnly=yes -o BatchMode=yes -i ~/.ssh/<key> <user>@<machine> true
```
Tests whether the key already logs in. `BatchMode=yes` makes it fail fast instead of
prompting, so you can tell whether a password is still needed.

```bash
read -rs -p "Remote password: " SSHPASS; echo; export SSHPASS
sshpass -e ssh-copy-id -i ~/.ssh/<key>.pub -o IdentitiesOnly=yes <user>@<machine>
unset SSHPASS
```
Installs your key on the machine. `read -rs` keeps the password off the screen and out
of shell history, and `sshpass -e` passes it through the environment so it never appears
in the process list (unlike `-p`). `unset` clears it right after. Install `sshpass` first
if it is missing. If you prefer, run `ssh-copy-id` on its own and type the password at its
prompt instead.

```bash
ssh -o IdentitiesOnly=yes -o BatchMode=yes -i ~/.ssh/<key> <user>@<machine> true
```
Confirms the machine now accepts the key without a password.

```bash
umask 077; touch ~/.ssh/config
grep -qE "^Host <alias>$" ~/.ssh/config || printf '\n%s\n' \
  "Host <alias>" \
  "  HostName <machine>" \
  "  User <user>" \
  "  IdentityFile $HOME/.ssh/<key>" \
  "  IdentitiesOnly yes" >> ~/.ssh/config
```
Creates `~/.ssh/config` with safe permissions if needed and appends the connection under
your chosen alias, but only if that alias is not already present.

```bash
ssh <alias> true
```
Verifies the saved alias connects.

## Notes / approval

Use this skill when the user wants to connect to a machine and save the connection.
Always show the key list and let the user choose. Only ask for the password if key
auth does not already work, and handle it as a transient secret: never echo, log,
store it, or pass it via `-p`. Do not overwrite `~/.ssh/config` or duplicate an
existing `Host` entry — check first, then append.
