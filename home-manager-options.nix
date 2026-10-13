{ flakeConfig, flakeInputs, optionPath ? [ "programs" "zsh" "bundle" ] }:
{ config, inputs, lib, pkgs, ... }:

let
  cfg = lib.attrByPath optionPath { } config;

  adapterModule =
    { config, lib, pkgs, ... }:
    let
      zshrc = pkgs.writeText "zsh-bundle-zshrc" ''
        ${config.zsh.rc}

        ${lib.optionalString config.sourceHomeZshrc ''
          if [[ -r "$HOME/.zshrc" && "$HOME/.zshrc" != "$ZDOTDIR/.zshrc" ]]; then
            source "$HOME/.zshrc"
          fi
        ''}
      '';
    in
    {
      options = {
        enable = lib.mkEnableOption "zsh bundle";

        executableName = lib.mkOption {
          type = lib.types.strMatching "[A-Za-z0-9._+-]+";
          default = "zsh-bundle";
          description = "Name of the generated zsh launcher installed into the user profile.";
        };

        package = lib.mkOption {
          type = lib.types.package;
          readOnly = true;
          description = "Generated zsh launcher package.";
        };

        sourceHomeZshrc = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether the generated zshrc sources ~/.zshrc when it exists.";
        };
      };

      config.package = pkgs.runCommand "zsh-bundle" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
        mkdir -p "$out/bin" "$out/share/zsh-bundle"
        cp ${zshrc} "$out/share/zsh-bundle/.zshrc"
        makeWrapper ${pkgs.zsh}/bin/zsh "$out/bin/${config.executableName}" \
          --set ZDOTDIR "$out/share/zsh-bundle"
      '';
    };
in
{
  options = lib.setAttrByPath optionPath (lib.mkOption {
    type = lib.types.submoduleWith {
      modules = flakeConfig.zsh.modules ++ [ adapterModule ];
      specialArgs = {
        inherit pkgs;
        inputs = flakeInputs;
        compileZshPlugin = flakeConfig.flake.lib.compileZshPlugin;
        dag = flakeInputs.dag.lib { inherit lib; };
      };
    };
    default = { };
    description = "zsh bundle configuration.";
  });

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
  };
}
