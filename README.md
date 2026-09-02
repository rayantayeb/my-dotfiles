# Rayan's Arch Linux Dotfiles

My personal Arch Linux and Hyprland configuration, documented as I build a clean, fast, and remotely accessible daily driver.

## System overview

| Component | Choice |
| --- | --- |
| Operating system | Arch Linux |
| Compositor | Hyprland (Wayland) |
| GPU | NVIDIA RTX 5070 |
| Terminal | Kitty |
| Shell | Zsh |
| Remote access | Tailscale + Sunshine + Moonlight |

## Repository layout

```text
.
├── .zshrc
├── docs/
│   └── remote-access.md
├── hypr/
│   └── hyprland.lua
└── scripts/
    └── install-remote-access.sh
```

## Install the dotfiles

Review the files before copying them because the commands below replace matching local configuration files.

```bash
git clone https://github.com/rayantayeb/my-dotfiles.git
cd my-dotfiles

mkdir -p ~/.config/hypr
cp hypr/hyprland.lua ~/.config/hypr/hyprland.lua
cp .zshrc ~/.zshrc
```

Restart Hyprland after changing `hyprland.lua`, or log out and back in.

## Remote access

The Arch desktop can be reached from a MacBook without router port forwarding:

```text
MacBook (Moonlight) -> Tailscale -> Arch (Sunshine) -> Hyprland
```

The complete setup, security notes, troubleshooting steps, and bandwidth estimates are in [Remote access with Tailscale, Sunshine, and Moonlight](docs/remote-access.md).

To install the Arch-side packages and services interactively:

```bash
./scripts/install-remote-access.sh
```

The script never stores Tailscale addresses, credentials, pairing PINs, or Sunshine certificates in this repository.

## Ricing journey

- **Day 1:** Created the repository and added the initial Hyprland configuration.
- **Day 2:** Set up the NVIDIA RTX 5070 driver, 144 Hz output, PipeWire audio, JetBrains Mono Nerd Font, the app launcher, and Zsh terminal customizations.
- **Day 3:** Added private remote access from macOS using Tailscale, OpenSSH, Sunshine, Moonlight, NVIDIA NVENC/AV1, and an SSH tunnel for the Sunshine web interface.
