{
  description = "LaTeX document compilation environment for Espresso audits";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # LaTeX environment with comprehensive package collection
        texlive-combined = pkgs.texlive.combine {
          inherit (pkgs.texlive)
            scheme-medium
            # Core packages
            latexmk
            # Common document classes and packages
            geometry
            hyperref
            graphics  # Contains graphicx
            xcolor
            tikz-cd
            pgfplots
            listings
            fancyhdr
            titlesec
            booktabs
            caption  # Also provides subcaption
            enumitem
            amsmath
            amsfonts
            amscls  # Contains amsthm
            mathtools
            # Fonts
            fontspec
            lualatex-math
            # Bibliography
            biber
            biblatex
            # Additional useful packages
            tcolorbox
            environ
            trimspaces
            algorithm2e
            algorithms
            # PDF tools
            pdfpages
            ;
        };

        # Helper script for compiling LaTeX documents
        compile-latex = pkgs.writeShellScriptBin "compile-latex" ''
          #!/usr/bin/env bash
          set -e
          
          if [ $# -eq 0 ]; then
            echo "Usage: compile-latex <file.tex>"
            echo "Compiles a LaTeX document to PDF using latexmk"
            exit 1
          fi
          
          FILE="$1"
          if [ ! -f "$FILE" ]; then
            echo "Error: File '$FILE' not found"
            exit 1
          fi
          
          echo "Compiling $FILE..."
          ${texlive-combined}/bin/latexmk -pdf -interaction=nonstopmode -file-line-error "$FILE"
          echo "Done! PDF generated."
        '';

        # Helper script for cleaning build artifacts
        clean-latex = pkgs.writeShellScriptBin "clean-latex" ''
          #!/usr/bin/env bash
          echo "Cleaning LaTeX build artifacts..."
          find . -type f \( \
            -name "*.aux" -o \
            -name "*.log" -o \
            -name "*.out" -o \
            -name "*.toc" -o \
            -name "*.fls" -o \
            -name "*.fdb_latexmk" -o \
            -name "*.synctex.gz" -o \
            -name "*.bbl" -o \
            -name "*.blg" -o \
            -name "*.bcf" -o \
            -name "*.run.xml" \
          \) -delete
          echo "Cleanup complete!"
        '';

      in
      {
        # Development shell with LaTeX tools
        devShells.default = pkgs.mkShell {
          buildInputs = [
            texlive-combined
            compile-latex
            clean-latex
            pkgs.gnumake
            pkgs.perl
            pkgs.python3
          ];

          shellHook = ''
            echo "LaTeX compilation environment loaded!"
            echo ""
            echo "Available commands:"
            echo "  compile-latex <file.tex>  - Compile a LaTeX document to PDF"
            echo "  clean-latex               - Remove LaTeX build artifacts"
            echo "  latexmk                   - Direct access to latexmk"
            echo ""
            echo "Example usage:"
            echo "  compile-latex document.tex"
            echo ""
          '';
        };

        # Package outputs for building specific documents
        # Example: nix build .#example-document
        packages = {
          # Add your LaTeX documents here as needed
          # example-document = pkgs.stdenvNoCC.mkDerivation {
          #   name = "example-document";
          #   src = ./.;
          #   buildInputs = [ texlive-combined ];
          #   buildPhase = ''
          #     latexmk -pdf -interaction=nonstopmode example.tex
          #   '';
          #   installPhase = ''
          #     mkdir -p $out
          #     cp example.pdf $out/
          #   '';
          # };
        };

        # Default package
        packages.default = compile-latex;
      }
    );
}
