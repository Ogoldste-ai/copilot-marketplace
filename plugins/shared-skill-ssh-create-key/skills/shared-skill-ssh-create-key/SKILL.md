---
name: shared-skill-ssh-create-key
description: Generate a new SSH key after showing encryption-type options and suggesting a user@host comment.
---

# Create SSH key

Trigger phrase: "create ssh key"

## Purpose

Generate a new SSH key pair safely: show the available encryption types so the
user can choose, suggest a key comment based on the user name and computer name,
and generate the key with a passphrase without overwriting any existing key.

## Assistant workflow

1. Show the existing keys with `ls -l ~/.ssh/*.pub` so the user sees what is already there and avoids clobbering a key.
2. Show the available encryption types and let the user pick one. Recommend `ed25519`:
   - `ed25519` — recommended default: modern, fast, short keys, strong security.
   - `ecdsa` — elliptic curve; use `-b 521` for the strongest curve. Prefer `ed25519` instead.
   - `rsa` — widest compatibility for old servers; use `-b 4096`.
   - `ed25519-sk` / `ecdsa-sk` — hardware-backed variants requiring a FIDO2 security key.
3. Suggest the key comment from the user name and computer name — `<user>@<host>` — using `whoami` and `hostname -s`. Let the user override it.
4. Choose the output file. Default to `~/.ssh/id_<type>` (for example `~/.ssh/id_ed25519`). If that file already exists, stop and ask before overwriting, or pick a different name such as `~/.ssh/id_<type>_<purpose>`.
5. Recommend setting a passphrase. Let `ssh-keygen` prompt for it interactively — never pass the passphrase on the command line, and never echo or store it.
6. Generate the key with the chosen type, comment, and file path.
7. Show the resulting public key and its fingerprint, and remind the user the private key must stay secret.

## Manual bash workflow

```bash
ls -l ~/.ssh/*.pub
```
Lists existing public keys so you do not accidentally overwrite one.

```bash
echo "$(whoami)@$(hostname -s)"
```
Builds the suggested key comment from your user name and computer name.

```bash
ssh-keygen -t ed25519 -C "$(whoami)@$(hostname -s)" -f ~/.ssh/id_ed25519
```
Generates an ed25519 key (recommended). It prompts for a passphrase interactively,
so the secret never appears on the command line. Change `-f` if the file exists.

```bash
ssh-keygen -t rsa -b 4096 -C "$(whoami)@$(hostname -s)" -f ~/.ssh/id_rsa
```
Alternative for maximum compatibility with older servers, using a 4096-bit RSA key.

```bash
ssh-keygen -t ecdsa -b 521 -C "$(whoami)@$(hostname -s)" -f ~/.ssh/id_ecdsa
```
Alternative ECDSA key using the strongest curve. Prefer ed25519 when possible.

```bash
ssh-keygen -lf ~/.ssh/id_ed25519.pub
```
Shows the fingerprint of the new key so you can confirm it was created.

## Notes / approval

Use this skill when the user wants to create a new SSH key. Always show the
encryption-type options and suggest the `<user>@<host>` comment before generating.
Never overwrite an existing key file without asking. Recommend a passphrase and let
`ssh-keygen` prompt for it — do not pass it on the command line, echo it, or store
it in the skill. The private key must never leave the machine.
