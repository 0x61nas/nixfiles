{ lib, ... }:
{
  options.vars.mainUser = lib.mkOption {
    type = lib.types.str;
    default = "anas";
    description = "The primary user name.";
  };
}
