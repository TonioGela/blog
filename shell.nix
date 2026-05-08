let
  pins = import ./npins;
  pkgsUnstable = import pins.nixpkgs-unstable { };
in
pkgsUnstable.mkShellNoCC {
  packages = [ pkgsUnstable.zola ];
}
