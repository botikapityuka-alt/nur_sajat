{ pkgs ? import <nixpkgs> { } }:

{
  emacs-custom = pkgs.callPackage ../emacs-custom { };
}
