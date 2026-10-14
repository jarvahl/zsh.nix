{ lib, ... }:
let
  testsDir = ../tests;
  tests = map (lib.removeSuffix ".nix") (
    builtins.attrNames (
      lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".nix" name) (
        builtins.readDir testsDir
      )
    )
  );
in
{
  imports = map (name: testsDir + "/${name}.nix") tests;

  perSystem =
    { config, pkgs, system, ... }:
    let
      integrationTests = pkgs.writeShellApplication {
        name = "integration-tests";
        runtimeInputs = [ pkgs.nix ];
        text = lib.concatMapStringsSep "\n" (check: ''
          echo "== ${check} =="
          nix build --print-build-logs ".#checks.${system}.${check}"
        '') (builtins.attrNames config.checks);
      };
    in
    {
      apps.integration-tests = {
        type = "app";
        program = lib.getExe integrationTests;
        meta.description = "Run all zsh.nix checks from the repository root";
      };
    };
}
