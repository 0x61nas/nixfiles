{ config, ... }: {
  home.sessionVariables = {
    CARGO_TARGET_DIR = "${config.home.homeDirectory}/.cargo-target";
  };

  home.file.".cargo/config.toml".source = ./config.toml;
}
