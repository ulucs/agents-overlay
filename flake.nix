{
  description = "Exploring integration between Nix and AI coding agents";
  nixConfig = {
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [ "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=" ];
  };

  inputs = {
    nixpkgs.follows = "llm-agents/nixpkgs";
    llm-agents.url = "github:numtide/llm-agents.nix";
  };

  outputs =
    {
      nixpkgs,
      llm-agents,
      ...
    }:
    let
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      overlays.default = import ./overlays { inherit llm-agents; };

      mkPerSystem =
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [ overlays.default ];
          };

          devShell = import ./devshell.nix { inherit pkgs; };
        in
        {
          formatter = pkgs.treefmt;
          devShells.default = devShell;
        };

      perSystemOutputs = builtins.listToAttrs (
        map (system: {
          name = system;
          value = mkPerSystem system;
        }) systems
      );
    in
    {
      devShells = builtins.mapAttrs (_: output: output.devShells) perSystemOutputs;
      formatter = builtins.mapAttrs (_: output: output.formatter) perSystemOutputs;
      inherit overlays;
    };
}
