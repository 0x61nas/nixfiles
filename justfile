DOAS := "doas"

@_default:
    just --choose

# Deploy the system.
system-switch:
    {{ DOAS }} nixos-rebuild switch --fallback --flake {{ justfile_directory() }}

# Deploy the home-manager generation.
home-switch USER="anas":
    home-manager switch --flake {{ justfile_directory() }}#{{ USER }}

# Update all the inputs.
update:
    nix flake update

# Update a specific input.
@update-input INPUT="_SHOW_CHOOSER_":
    #!/usr/bin/env bash
    set -euxo pipefail
    input={{  INPUT }}
    if [[ $input == "_SHOW_CHOOSER_" ]]; then
        input="$(just choose-input)"
    fi
    nix flake update $input

# Show an interactive chooser for inputs.
@choose-input:
    nix flake metadata --json {{ justfile_directory() }} | jq -r \
    '.locks.nodes | to_entries[] | .value.inputs | select(. != null) | to_entries[] | .key' | sort | uniq \
    | fzf --height=~35% --cycle
history:
    nix profile history --profile /nix/var/nix/profiles/system

home-generations:
    home-manager generations

repl:
    nix repl -f flake:nixpkgs

# remove all generations older than N days
clean DAYS="7":
    {{ DOAS }} nix profile wipe-history --profile /nix/var/nix/profiles/system  --older-than {{ DAYS }}d

gc:
    # garbage collect all unused nix store entries
    {{ DOAS }} nix-collect-garbage --delete-old


nvim-clean:
  rm -rf $HOME/.config/nvim/

nvim-test: nvim-clean
  rsync -avz --copy-links --chmod=D2755,F744 {{ justfile_directory() }}/dev/nvim/nvim $HOME/.config
