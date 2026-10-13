{ config, inputs, lib, ... }:

let
  flakeConfig = config;
in
{
  flake.homeManagerModules.default =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.programs.nzf;
    in
    {
      options.programs.nzf = {
        enable = lib.mkEnableOption "Nix zsh framework";

        settings.zsh = lib.mkOption {
          type = lib.types.submoduleWith {
            modules = flakeConfig.zsh.modules;
            specialArgs = {
              inherit inputs pkgs;
              compileZshPlugin = flakeConfig.flake.lib.compileZshPlugin;
              dag = inputs.dag.lib { inherit lib; };
            };
          };
          default = { };
          description = "Nix zsh framework configuration.";
        };
      };

      config = lib.mkIf cfg.enable {
        programs.zsh.enable = lib.mkDefault true;
        programs.zsh.initContent = lib.mkBefore cfg.settings.zsh.zsh.rc;
      };
    };

  flake-file.inputs.home-manager = {
    inputs.nixpkgs.follows = "nixpkgs";
    url = "github:nix-community/home-manager";
  };
}
