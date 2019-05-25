{ fetchurl ? import <nix/fetchurl.nix>
}:

fetchurl (builtins.fromJSON (builtins.readFile ./url.json))
