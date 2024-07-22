{
  description = "A repository for verifying a RISCV mmu";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.*.tar.gz";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      checks = forAllSystems (system: {
        pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            nixpkgs-fmt.enable = true;

            convco.enable = true;
            clippy.enable = true;
            cargo-check.enable = true;
            check-toml.enable = true;
            rustfmt.enable = true;
            check-merge-conflicts.enable = true;
            trim-trailing-whitespace.enable = true;
            svlint = {
              enable = false; # would be cool to enable this at some point later

              # The name of the hook (appears on the report table):
              name = "svlint";

              # The command to execute (mandatory):
              entry = "svlint";

              # The pattern of files to run on (default: "" (all))
              # see also https://pre-commit.com/#hooks-files
              files = "\\.(sv|svh|svp|v|vh|vp)$";

              # List of file types to run on (default: [ "file" ] (all files))
              # see also https://pre-commit.com/#filtering-files-with-types
              # You probably only need to specify one of `files` or `types`:
              types = [ "file" ];

              # Exclude files that were matched by these patterns (default: [ ] (none)):
              excludes = [ ];

              # The language of the hook - tells pre-commit
              # how to install the hook (default: "system")
              # see also https://pre-commit.com/#supported-languages
              language = "system";

              # Set this to false to not pass the changed files
              # to the command (default: true):
              pass_filenames = true;

              # Which git hooks the command should run for (default: [ "pre-commit" ]):
              stages = [ "pre-commit" ];
            };
          };
        };
      });

      devShells = forAllSystems (system: {
        default = nixpkgs.legacyPackages.${system}.mkShell {
          inherit (self.checks.${system}.pre-commit-check) shellHook;
          buildInputs = self.checks.${system}.pre-commit-check.enabledPackages;
          packages = with nixpkgs.legacyPackages.${system}; [
            svlint
          ];
        };
      });
    };
}
