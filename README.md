<h1 align="center">
  <div>
    <a href="https://github.com/0x61nas/nixfiles/issues">
        <img src="https://img.shields.io/github/issues/0x61nas/nixfiles?color=fab387&labelColor=303446&style=for-the-badge">
    </a>
    <a href="https://github.com/0x61nas/nixfiles/stargazers">
        <img src="https://img.shields.io/github/stars/0x61nas/nixfiles?color=ca9ee6&labelColor=303446&style=for-the-badge">
    </a>
    <a href="https://github.com/0x61nas/nixfiles">
        <img src="https://img.shields.io/github/repo-size/0x61nas/nixfiles?color=ea999c&labelColor=303446&style=for-the-badge">
    </a>
    <a href="https://github.com/0x61nas/nixfiles/LICENSE">
        <img src="https://img.shields.io/static/v1.svg?style=for-the-badge&label=License&message=MIT&logoColor=ca9ee6&colorA=313244&colorB=cba6f7"/>
    </a>
    <br>
    </div>
        <img href="https://builtwithnix.org" src="https://builtwithnix.org/badge.svg"/>
   </h1>

<div align="center">
<h1>
❄️ NixOS dotfiles ❄️
</h1>
</div>

![me](./background.png)

```mint
⠀⠀   🌸 Setup / ARCHY DWM 🌸
 -----------------------------------
 ╭─ Distro  -> NixOS
 ├─ Editor  -> Neovim
 ├─ Browser -> Firefox
 ├─ Shell   -> ZSH
 ╰─ Resource Monitor -> Btop
 ╭─ Model -> LENOVO LEGION Y540-15IRH
 ├─ CPU   -> Intel i7-9750H @ 4.50 GHz
 ├─ GPU   -> NVIDIA GeForce GTX 1660 Ti Mobile
 ╰─ Resolution -> 1920x1080@144hz
 ╭─ WM       -> Archy DWM
 ├─ Terminal -> Arych terminal
 ├─ Theme    -> Gruvbox Dark Hard
 ├─ Icons    -> Gruvbox-Plus-Dark
 ╰─ Font     -> JetBrains Mono Nerd Font
               󰣨         
```

> [!Note]
> This repo is still experimental, USE IT ON YOUR OWN RESPONSIBILITY

> [!Note]
> This readme file isn't completed yet, and it might have outdated or even evil information

> [!Note]
> WHAT ABOUT GOING OUTSIDE?

> [!Note]
> STOP

## Commands you should know:

- Rebuild and switch to change the system configuration (in the configuration directory):

```
just s
```

OR

```
doas nixos-rebuild switch --flake '.#anas'
```

- Connect to internet (Change what's inside the brackets with your info).

```
iwctl --passphrase [passphrase] station [device] connect [SSID]
```

## Installation

I'll guide you through the Installation, but first make sure to download the Minimal ISO image available at [NixOS](https://nixos.org/download#nixos-iso) and make a bootable drive with it.
and an ethernet cable to make things easier. We shall begin!

> Only follow these steps after using the bootable drive, changing BIOS boot priority and getting into the installation!

### Pre-install (drive preparation)

```sh
video=1920x1080
setfont ter-128n
# configure networking as needed (skip this if you're using ethernet)
sudo -i
lsblk # check info about partitions and the device you want to use for the installation
gdisk /dev/vda #change according to your system, for me it's /dev/nvme0n1
# then configure 600M type ef00, rest ext4 type 8300 as described below
# Type "n" to make a new partition, choose the partition number, first sector can be default but last sector should be 600M. Hex code for EFI is ef00.
# Now type n again to make another partition, this time we'll leave everything as default. After finishing these steps, make sure to write it to the disk by typing "w".
lsblk
mkfs.fat -F 32 -n boot /dev/vda1
mkfs.ext4 -L nixos /dev/vda2
mount /dev/disk/by-label/nixos /mnt
mkdir /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot
```
### The actual installation

After mounting the partitions, you can move to the second part...

```sh
# go inside a nix shell with the specified programs
nix-shell -p git nixUnstable neovim
# create this folder if necessary
mkdir -p /mnt/etc/
# clone the repo
git clone https://github.com/anas/nixfiles.git /mnt/etc/nixos --recurse-submodules
# generate the config and take some files
nixos-generate-config --root /mnt --show-hardware-config > /mnt/etc/nixos/hosts/anas/hardware-configuration.nix
# make sure you're in this path
cd /mnt/etc/nixos
# Install my config:
nixos-install --flake '.#anas'
```
