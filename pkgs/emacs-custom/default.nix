# pkgs/emacs-custom/default.nix
{ pkgs ? import <nixpkgs> { } }:

let
  rawEmacs = (pkgs.emacs.override {
    withTreeSitter = true;
    withNativeCompilation = true;
  }).overrideAttrs (oldAttrs: rec {
    pname = "emacs-custom-raw";
    version = "29.4";

    src = pkgs.fetchurl {
      url = "https://ftp.gnu.org/gnu/emacs/emacs-${version}.tar.gz";
      hash = "sha256-Gtsbmixs2zFmCbPoawuhzrUj+N5UDP3aKuyVtqU0Or8=";
    };

    patches = [ ];

    postPatch = ''
      substituteInPlace src/treesit.c \
        --replace-fail "ts_language_version" "ts_language_abi_version"
    '';
  });

in
pkgs.symlinkJoin {
  name = "emacs-custom-final-29.4";
  paths = [ rawEmacs ];

  nativeBuildInputs = [ pkgs.makeWrapper ];

  postBuild = ''
    rm -f $out/bin/emacs $out/bin/emacs-29.4

    # Itt a trükk: a NYERS (unwrapped) GCC-t és binutilst használjuk,
    # így nem akad fenn a NixOS wrapper ellenőrzésein futásidőben.
    local unwrappedGcc="${pkgs.stdenv.cc.cc}"
    local unwrappedBinutils="${pkgs.binutils-unwrapped}"

    makeWrapper ${rawEmacs}/bin/emacs-29.4 $out/bin/emacs \
      --prefix PATH : "''${unwrappedGcc}/bin:''${unwrappedBinutils}/bin:${pkgs.gnumake}/bin:${pkgs.coreutils}/bin" \
      --set CC "''${unwrappedGcc}/bin/gcc" \
      --set LIBRARY_PATH "${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.stdenv.cc.libc}/lib" \
      --set NIX_CFLAGS_COMPILE "-B${pkgs.stdenv.cc.libc}/lib -B${pkgs.stdenv.cc.cc.lib}/lib -I${pkgs.stdenv.cc.libc.dev}/include"

    ln -s emacs $out/bin/emacs-29.4
  '';
}
