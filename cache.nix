{ ... }: {
  nix.settings = {
    substituters = [
      #"https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
      "https://cachix.org"
    ];
    trusted-public-keys = [
      #"hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "anas-nur.cachix.org-1:veqNfnPw6jSN7UCqQHvnKk/zY1bxmUu6S8pjfsqrM48="
      "mayuri.cachix.org-1:k9dEoGqRBy9Sv7MLSuMDxN3eZZ6H56kRdVIowyy1k10="
    ];
  };
}
