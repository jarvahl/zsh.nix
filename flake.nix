# DO-NOT-EDIT. This file was auto-generated using github:denful/flake-file.
# Use `nix run .#write-flake` to regenerate it.
{
  outputs = inputs: import ./outputs.nix inputs;

  inputs = {
    dag = {
      url = "github:denful/dag";
    };
    flake-file = {
      url = "github:denful/flake-file";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    import-tree = {
      url = "github:denful/import-tree";
    };
    nixpkgs = {
      url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
