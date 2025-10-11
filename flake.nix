{
  description =
    "Development environment with pandoc and reveal.js presentation builder";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        presentation = pkgs.stdenv.mkDerivation {
          name = "of25-nix-presentation";
          src = ./.;

          buildInputs = with pkgs; [ pandoc ];

          buildPhase = ''
            mkdir -p $out

            pandoc slides.md \
              -t revealjs \
              -s \
              --css slides.css \
              -o $out/index.html \
              --slide-level=2 \
              --variable theme=white \
              --variable transition=slide
          '';

          installPhase = ''
            cp slides.css $out/
          '';
        };

      in {
        packages.default = presentation;

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [ pandoc ];

          shellHook = ''
            echo "Development environment with pandoc ready!"
            echo "Pandoc version: $(pandoc --version | head -n1)"
            echo ""
            echo "To build the presentation, run: nix build"
            echo "To serve locally, run: python -m http.server 8000 -d result/"
          '';
        };
      });
}
