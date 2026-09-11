let
  pins = import ./npins;
  pkgs = import pins.nixpkgs-unstable { };
  # zola serve, with drafts on: local is where you want to see them
  serve = pkgs.writeShellScriptBin "serve" ''exec zola serve --drafts "$@"'';
in
pkgs.mkShellNoCC {
  packages = [ pkgs.zola serve ];
}
