# Custom Packages Overlay
# Packages not available in nixpkgs or requiring customization
{ pkgs }:

{
  linear = pkgs.callPackage ./linear.nix { };
}
