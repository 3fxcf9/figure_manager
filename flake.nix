{
  description = "SVG figure manager for my note-taking workflow";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {inherit system;};
        vlang = pkgs.vlang;
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            vlang
            rofi
            inkscape
            inotify-tools
            scour
          ];
        };

        packages.figure_manager = pkgs.stdenv.mkDerivation {
          pname = "figure_manager";
          version = "0.1.0";

          src = self;

          nativeBuildInputs = [
            vlang
            pkgs.makeWrapper
          ];

          buildPhase = ''
            export HOME=$TMPDIR
            v -prod -o figure_manager .
          '';

          installPhase = ''
            mkdir -p $out/bin
            cp figure_manager $out/bin/

            wrapProgram $out/bin/figure_manager \
              --prefix PATH : "${pkgs.inkscape}/bin:${pkgs.inotify-tools}/bin:${pkgs.scour}/bin:${pkgs.tofi}/bin"
          '';
        };

        apps.figure_manager = flake-utils.lib.mkApp {
          drv = self.packages.${system}.figure_manager;
        };
      }
    );
}
