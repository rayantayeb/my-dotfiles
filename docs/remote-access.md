# Remote access with Tailscale, Sunshine, and Moonlight

This setup provides low-latency access to the existing Hyprland session from macOS. Tailscale carries the private network traffic, Sunshine captures and encodes the Arch desktop, and Moonlight displays and controls it on the MacBook.

```text
MacBook (Moonlight) -> encrypted Tailscale connection -> Arch (Sunshine) -> Hyprland
```

No router port forwarding is required.

## What runs where

| Device | Software | Purpose |
| --- | --- | --- |
| Arch Linux PC | Tailscale | Private network connectivity |
| Arch Linux PC | OpenSSH | Terminal access and a secure Sunshine web UI tunnel |
| Arch Linux PC | Sunshine | Desktop capture and NVIDIA hardware encoding |
| MacBook | Tailscale | Access to the same tailnet |
| MacBook | Moonlight | Remote desktop client |

## Automated Arch installation

Run the installer as the normal desktop user, not as root:

```bash
./scripts/install-remote-access.sh
```

The script:

1. Confirms that it is running on Arch Linux.
2. Offers to add Sunshine's official LizardByte pacman repository.
3. Creates a timestamped backup of `/etc/pacman.conf` before changing it.
4. Installs Tailscale, OpenSSH, and Sunshine with a full system upgrade.
5. Enables `tailscaled`, `sshd`, and the Sunshine user service.

Authentication and pairing stay manual so no account details or secrets are written to disk by the script.

## Manual Arch installation

### 1. Install and connect Tailscale

```bash
sudo pacman -Syu --needed tailscale openssh
sudo systemctl enable --now tailscaled sshd
sudo tailscale up
```

Open the authentication URL printed by `tailscale up`, sign in, and verify the connection:

```bash
tailscale status
tailscale ip -4
```

### 2. Add Sunshine's official repository

Add the following block once to `/etc/pacman.conf`:

```ini
[lizardbyte]
SigLevel = Optional
Server = https://github.com/LizardByte/pacman-repo/releases/latest/download
```

Then perform a full upgrade and install Sunshine:

```bash
sudo pacman -Syu --needed lizardbyte/sunshine
```

### 3. Start Sunshine

```bash
systemctl --user enable --now app-dev.lizardbyte.app.Sunshine
systemctl --user status app-dev.lizardbyte.app.Sunshine --no-pager
```

The service should report `Active: active (running)`. NVIDIA systems can verify hardware encoder detection with:

```bash
journalctl --user -u app-dev.lizardbyte.app.Sunshine -b --no-pager | grep -Ei 'nvenc|encoder|capture|error'
```

The tested RTX 5070 setup detected `av1_nvenc` successfully.

## Configure Sunshine securely from the MacBook

Sunshine protects its web UI against requests from unexpected origins. Instead of weakening CSRF protection, forward the local web UI through SSH.

On the MacBook, open a dedicated Terminal window:

```bash
ssh -L 47990:localhost:47990 <arch-user>@<arch-tailscale-ip>
```

Keep that SSH session open and visit:

```text
https://127.0.0.1:47990
```

The browser will warn about Sunshine's self-signed certificate. After verifying that the address and SSH tunnel are correct, continue and create the Sunshine web UI credentials. Do not commit those credentials, `sunshine_state.json`, or Sunshine certificates.

The SSH tunnel is required only when managing the Sunshine web UI. Moonlight connects directly through Tailscale.

## Pair Moonlight

1. Install Tailscale and Moonlight on the MacBook.
2. Sign in to the same tailnet used by the Arch PC.
3. In Moonlight, add the Arch PC's Tailscale IP (`100.x.y.z`) manually.
4. Select the PC to display a four-digit pairing PIN.
5. Open the Sunshine web UI through the SSH tunnel and select **PIN**.
6. Enter the PIN and a descriptive client name, such as `MacBook`.
7. Return to Moonlight and select **Desktop**.

Keep real Tailscale IPs and pairing PINs out of public screenshots and commits.

## Everyday use

The following must be true before connecting:

- The Arch PC is powered on.
- Tailscale is connected on both devices.
- A Hyprland graphical session is logged in on Arch.
- The Sunshine user service is running.

Then open Moonlight, select the Arch PC, and launch **Desktop**. SSH is not required for the stream itself.

After a reboot, Sunshine cannot capture Hyprland until a graphical session exists. Automatic login, sleep settings, and Wake-on-LAN are separate optional improvements for unattended access.

## Suggested Moonlight settings

For general desktop work over the internet, begin with:

- Resolution: `1920x1080`
- Frame rate: `60 FPS`
- Video bitrate: `15 Mbps`
- Codec: `AV1` when both client and host support it; otherwise use HEVC

Increase the bitrate only after confirming that the connection is stable.

### Approximate data use

Video bitrate determines most of the data usage. A practical estimate including small protocol and audio overhead is:

```text
data per hour in GB ~= bitrate in Mbps x 0.5
```

| Preset | Typical bitrate | Approximate data per hour |
| --- | ---: | ---: |
| 720p 60 FPS | 5-10 Mbps | 2.5-5 GB |
| 1080p 60 FPS | 10-20 Mbps | 5-10 GB |
| 1080p 120 FPS | 20-35 Mbps | 10-17 GB |
| 1440p 60 FPS | 20-35 Mbps | 10-17 GB |
| 1440p 120 FPS | 35-60 Mbps | 17-30 GB |
| 4K 60 FPS | 40-80 Mbps | 20-40 GB |

When both devices establish a direct connection on the same local network, the stream normally stays local. When connecting from outside the home, the Arch connection supplies the upload and the MacBook connection receives the same stream as download.

## Troubleshooting

### SSH connection times out

Confirm that Tailscale is installed and connected on both devices, then test the peer:

```bash
tailscale ping <arch-tailscale-ip>
```

On Arch, verify SSH:

```bash
sudo systemctl status sshd --no-pager
```

### SSH reports `Permission denied`

Use the Arch account name returned by `whoami`, not the PC hostname. Password input is intentionally invisible in the terminal.

### Sunshine reports a CSRF protection error

Do not broadly allow remote web origins. Use the SSH tunnel described above and open `https://127.0.0.1:47990`.

### The Sunshine web UI stays blank after account creation

Keep the SSH tunnel open and retry `https://127.0.0.1:47990` in a private browser window. This also avoids stale browser storage from the first-run page.

### Moonlight does not find the PC automatically

Add the Arch PC's Tailscale IP manually. Discovery broadcasts are not required for a direct connection.

### Sunshine is running but the desktop does not open

Check that Hyprland is already logged in, then inspect Sunshine's current-boot log:

```bash
journalctl --user -u app-dev.lizardbyte.app.Sunshine -b --no-pager
```
