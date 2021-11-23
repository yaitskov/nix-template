{ system ? builtins.currentSystem or "x86_64-linux", ghc ? "ghc8107" }:

let
  nix = import ./nix;

  pkgs = nix.pkgSetForSystem system {
    config = {
      allowBroken = true;
      allowUnfree = true;
    };
  };

  inherit (pkgs) lib;

  inherit (pkgs.haskell.lib)
    doCheck dontCheck enableCabalFlag enableSharedExecutables;

  haskellPkgSetOverlay = pkgs.callPackage ./nix/haskell/overlay.nix {
    inherit (nix) sources;
  };

  myHsAppSourceRegexes = [
    "^src.*$"
    "^test.*$"
    "^exec.*$"
    "^.*\\.cabal$"
    "package.yaml"
    "Build.hs"
    "^LICENSE$"
  ];

  myHsAppBase = enableSharedExecutables (dontCheck
    (haskellPkgs.callCabal2nix "myhsapp"
      (lib.sourceByRegex ./. myHsAppSourceRegexes) { }));

  myHsAppOverlay = _hfinal: _hprev: { myhsapp = myHsAppBase; };

  baseHaskellPkgs = pkgs.haskell.packages.${ghc};

  haskellOverlays = [ haskellPkgSetOverlay myHsAppOverlay ];

  haskellPkgs = baseHaskellPkgs.override (old: {
    overrides =
      builtins.foldl' pkgs.lib.composeExtensions (old.overrides or (_: _: { }))
      haskellOverlays;
  });

  haskellLanguageServer =
    pkgs.haskell.lib.overrideCabal haskellPkgs.haskell-language-server
    (_: { enableSharedExecutables = true; });

  shell = haskellPkgs.shellFor {
    packages = _: [];

    # include any recommended tools
    nativeBuildInputs = [ haskellLanguageServer ] ++ (with pkgs; [
      cabal-install
      ghcid
      hlint
      niv
      hpack
    ]);

    shellHook = ''
      echo shell hook
      hpack
    '';
  };

  myhsapp = haskellPkgs.myhsapp;
in {
  inherit haskellPkgs;
  inherit ghc;
  inherit pkgs;
  inherit shell;
  inherit myhsapp;
  inherit haskellOverlays;
  inherit haskellLanguageServer;
}
