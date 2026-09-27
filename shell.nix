let
  pins = import ./npins;
  pkgs = import pins.nixpkgs-unstable { };
  serve = pkgs.writeShellScriptBin "serve" ''exec zola serve --drafts "$@"'';
in
pkgs.mkShellNoCC {
  packages = [ pkgs.zola serve ];
  shellHook = ''echo -e "There's a \033[92;5;1mserve\033[0m command for fast prototyping here"'';
}
