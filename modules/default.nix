{ inputs, ... }:
{
  flake-file.inputs = {
    dag.url = "github:denful/dag";
    flake-file.url = "github:denful/flake-file";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    import-tree.url = "github:denful/import-tree";
    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst";
  };

  imports = with inputs.flake-file.flakeModules; [
    auto-follow
    default
    import-tree
  ];

  systems = inputs.nixpkgs.lib.systems.flakeExposed;
}
