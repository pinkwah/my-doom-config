{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=release-25.11";

    doomemacs-src = {
      url = "github:doomemacs/doomemacs";
      flake = false;
    };

    doom-emacs = {
      url = "github:marienz/nix-doom-emacs-unstraightened";
      inputs.nixpkgs.follows = "";
      inputs.doomemacs.follows = "doomemacs-src";
    };

    tree-sitter-astro-src = {
      url = "github:virchau13/tree-sitter-astro";
      flake = false;
    };

    tree-sitter-bicep-src = {
      url = "github:tree-sitter-grammars/tree-sitter-bicep";
      flake = false;
    };
  };

  outputs = inputs@{ self, ... }:
  let
    extra-grammars = tree-sitter: {
      tree-sitter-astro = tree-sitter.buildGrammar {
        language = "astro";
        version = "git";
        src = inputs.tree-sitter-astro-src;
      };

      tree-sitter-bicep = tree-sitter.buildGrammar {
        language = "bicep";
        version = "git";
        src = inputs.tree-sitter-bicep-src;
      };
    };

    pkgs-with-overlays = system: import inputs.nixpkgs {
      inherit system;
      overlays = [
        inputs.doom-emacs.overlays.default
        (final: prev: {
          tree-sitter = prev.tree-sitter.override {
            extraGrammars = extra-grammars prev.tree-sitter;
          };
        })
      ];
    };

    doom-emacs = system: pname:
    let pkgs = pkgs-with-overlays system; in pkgs.emacsWithDoom {
      doomDir = ./.;
      doomLocalDir = "~/.local/share/pinkwah/doom-emacs";
      emacs = pkgs.${pname};
      lspUsePlists = true;
      extraPackages = epkgs: [ epkgs.treesit-grammars.with-all-grammars ];
    };

  in {
    devShells.x86_64-linux.default =
      let
        pkgs = import inputs.nixpkgs { system = "x86_64-linux"; };
        lib = pkgs.lib;
      in pkgs.mkShell {
        name = "pinkwah-doom-emacs-env";

        shellHook = ''
          export EMACS="${lib.getExe pkgs.emacs30}"
          export EMACSDIR="${inputs.doomemacs-src}"
          export DOOMDIR="$PWD"
          export DOOMLOCALDIR="$PWD/_tmp/doom-local"
        '';
    };

    packages.x86_64-linux.default = doom-emacs "x86_64-linux" "emacs30-pgtk";
    packages.x86_64-linux.emacs = doom-emacs "x86_64-linux" "emacs30";
    packages.aarch64-linux.default = doom-emacs "aarch64-linux" "emacs30-pgtk";
    packages.aarch64-darwin.default = doom-emacs "aarch64-darwin" "emacs30-macport";
  };
}
