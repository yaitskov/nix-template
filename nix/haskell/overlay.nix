{ haskell, lib, sources }:

# In-order:
#   - the 'final', or fixed-point, Haskell package set environment resulting
#     from the application of this overlay as well as any others it may be
#     composed with
#   - the 'previous' Haskell package set environment that this overlay will have
#     been composed with
#
# Practically speaking:
#   - 'hfinal' can be used to operate over the resulting package set that this
#     overlay may be used to create, however if one is not careful they can
#     cause an infinitely recursive definition by defining something in terms of
#     itself
#   - 'hprev' can be used to operate over the package set environment as it
#     existed strictly _before_ this overlay will have been applied; it can't
#     use the final package set in any way, but it also can't infinitely recurse
#     upon itself

let
  inherit (haskell.lib) doJailbreak dontCheck doHaddock;

  # 'fakeSha256' is helpful when adding new packages
  #
  # Set 'sha256 = fakeSha256', then replace the SHA with the one reported by
  # Nix when the build fails with a SHA mismatch error.
  inherit (lib) fakeSha256 nameValuePair listToAttrs;

in hfinal: hprev:

(listToAttrs (map (a:
  nameValuePair a.name
  (dontCheck (hfinal.callCabal2nix a.name a.source { }))) [
    {
      name = "beam-core";
      source = sources.beam + "/beam-core";
    }
    {
      name = "beam-sqlite";
      source = sources.beam + "/beam-sqlite";
    }
  ])) // {
    relude = hfinal.callHackageDirect {
      pkg = "relude";
      ver = "1.0.0.1";
      sha256 = "sha256-tpv6QvG8jhAO8tvfehPuyqJBQNosDaS/83cwMkYQl5g=";
    } { };
  }
