#!/usr/bin/env bash

set -Eeuo pipefail

readonly PACMAN_CONF="/etc/pacman.conf"
readonly LIZARDBYTE_HEADER="[lizardbyte]"
readonly LIZARDBYTE_SERVER="https://github.com/LizardByte/pacman-repo/releases/latest/download"
readonly SUNSHINE_SERVICE="app-dev.lizardbyte.app.Sunshine"

log() {
    printf '\n==> %s\n' "$1"
}

die() {
    printf 'Error: %s\n' "$1" >&2
    exit 1
}

if (( EUID == 0 )); then
    die "Run this script as your normal desktop user. It will request sudo only when required."
fi

[[ -r /etc/arch-release ]] || die "This installer supports Arch Linux only."
command -v sudo >/dev/null 2>&1 || die "sudo is required."

if ! grep -Fqx "$LIZARDBYTE_HEADER" "$PACMAN_CONF"; then
    printf 'Sunshine uses the official LizardByte pacman repository.\n'
    printf 'This installer can add it to %s after making a backup.\n' "$PACMAN_CONF"
    read -r -p "Continue? [y/N] " reply

    case "$reply" in
        y|Y|yes|YES)
            backup_path="${PACMAN_CONF}.backup.$(date -u +%Y%m%dT%H%M%SZ)"
            log "Backing up pacman.conf to $backup_path"
            sudo cp --preserve=mode,ownership,timestamps "$PACMAN_CONF" "$backup_path"

            log "Adding the official LizardByte repository"
            printf '\n%s\nSigLevel = Optional\nServer = %s\n' \
                "$LIZARDBYTE_HEADER" "$LIZARDBYTE_SERVER" \
                | sudo tee -a "$PACMAN_CONF" >/dev/null
            ;;
        *)
            die "Repository setup cancelled; no changes were made."
            ;;
    esac
else
    log "LizardByte repository is already configured"
fi

log "Upgrading Arch and installing remote-access packages"
sudo pacman -Syu --needed tailscale openssh lizardbyte/sunshine

log "Enabling Tailscale and OpenSSH"
sudo systemctl enable --now tailscaled.service sshd.service

log "Enabling Sunshine for the current desktop user"
systemctl --user enable --now "$SUNSHINE_SERVICE.service"

log "Installation complete"
printf '%s\n' \
    "1. Connect Arch to your tailnet: sudo tailscale up" \
    "2. Verify the devices: tailscale status" \
    "3. Open the Sunshine UI from the Mac through an SSH tunnel:" \
    "   ssh -L 47990:localhost:47990 <arch-user>@<arch-tailscale-ip>" \
    "4. Visit https://127.0.0.1:47990 and create Sunshine credentials." \
    "5. Add the Arch Tailscale IP in Moonlight and pair with the PIN page."
