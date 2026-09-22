{ inputs, ... }:
{
  # keep the nix registry in sync with the flake inputs so that entries
  # like `nix run nixpkgs#...` always resolve to the pinned revisions.
  nix.registry = {
    nixpkgs.flake = inputs.nixpkgs;
    nixpkgs-unstable.flake = inputs.nixpkgs-unstable;
    nur.flake = inputs.nur;
    home-manager.flake = inputs.home-manager;
    nix-alien.flake = inputs.nix-alien;
    impermanence.flake = inputs.impermanence;
    lqth.flake = inputs.lqth;
    archy-dwm.flake = inputs.archy-dwm;
    nix-jetbrains-plugins.flake = inputs.nix-jetbrains-plugins;
  };
}
