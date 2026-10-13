{ config, inputs, ... }:

{
  flake.homeManagerModules.default = import ../home-manager-options.nix {
    flakeConfig = config;
    flakeInputs = inputs;
    optionPath = [
      "programs"
      "zsh"
      "bundle"
    ];
  };

  flake-file.inputs.home-manager = {
    inputs.nixpkgs.follows = "nixpkgs";
    url = "github:nix-community/home-manager";
  };
}
