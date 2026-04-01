{ llm-agents }:
final: prev:
let
  lib = import (llm-agents + /lib) {
    inputs.nixpkgs.lib = prev.lib;
  };

  packageNames = builtins.filter (name: builtins.pathExists ((llm-agents + /packages) + "/${name}/package.nix")) (
    builtins.attrNames (builtins.readDir (llm-agents + /packages))
  );

  npmPackumentSupport = final.callPackage (llm-agents + /lib/fetch-npm-deps.nix) { };
  fetchCargoVendor = final.callPackage (llm-agents + /lib/fetch-cargo-vendor/fetch-cargo-vendor.nix) { };

  callPackage = lib.callPackageWith (
    final
    // {
      inherit lib;
      flake = { inherit lib; };
      pkgs = final;
      inherit fetchCargoVendor;
    }
    // npmPackumentSupport
  );

  packageOverrides = {
    claudebox = callPackage (llm-agents + /packages/claudebox/package.nix) {
      claude-code = final.claude-code;
      sourceDir = "${callPackage (llm-agents + /packages/claudebox/source.nix) { }}/src";
    };
  };

  packages = lib.genAttrs packageNames (
    name:
    if builtins.hasAttr name packageOverrides then
      packageOverrides.${name}
    else
      callPackage ((llm-agents + /packages) + "/${name}/package.nix") { }
  );
in
packages
// {
  llm-agents = packages;
}
