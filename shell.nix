let
  pins = import ./npins;
  pkgs = import pins.nixpkgs-unstable { };
  serve = pkgs.writeShellScriptBin "serve" ''exec zola serve --drafts "$@"'';
in
pkgs.mkShellNoCC {
  packages = [ pkgs.zola serve ];
}
