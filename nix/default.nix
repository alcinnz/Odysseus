{ pkgs ? import <nixpkgs> {}
, lib ? pkgs.lib
, makeScope ? lib.makeScope
, newScope ? pkgs.newScope
, pantheon ? pkgs.pantheon
}:

with makeScope newScope (self: with self; {
  inherit (pantheon) granite vala;
  odysseus = self.callPackage ./odysseus.nix {};
});

odysseus
