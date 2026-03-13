{
  description = "ADBC lead_demoElixir development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      with pkgs; {
        devShells.default = mkShell {
          buildInputs = [
	          beamMinimal28Packages.elixir_1_19
            duckdb
            sqlite
          ]
          ++ lib.optionals stdenv.isLinux [
            # For ExUnit Notifier on Linux.
            libnotify

            # For file_system on Linux.
            inotify-tools
          ]
          ++ lib.optionals stdenv.isDarwin ([
            # For ExUnit Notifier on macOS.
            terminal-notifier
          ]);

          shellHook = ''
            if [ -z "$NIX_SHELL_NESTED" ]; then
              export NIX_SHELL_NESTED=1
              export PS1="💧\e[38;2;78;193;245madbc_leak_demo\e[0m $PS1"
              export ERL_AFLAGS="-kernel shell_history enabled -kernel shell_history_path '\"$PWD/.erlang-history\"' "

              # test if there is a flake.nix in the current directory
              if [ -f ./flake.nix ]; then
                # now check if .nix-mix is there, and also .nix-hex
                if [ -d .nix-mix ] && [ -d .nix-hex ]; then
                  echo "Found .nix-mix and .nix-hex, skipping mix and hex setup"
                else
                  echo "No .nix-mix or .nix-hex found, setting up"
                  mkdir -p .nix-mix
                  mkdir -p .nix-hex
                fi

                export MIX_HOME=$PWD/.nix-mix
                export HEX_HOME=$PWD/.nix-hex
                export ERL_LIBS=$HEX_HOME/lib/erlang/lib

                # concats PATH
                export PATH=$MIX_HOME/bin:$PATH
                export PATH=$MIX_HOME/escripts:$PATH
                export PATH=$HEX_HOME/bin:$PATH
              else
                echo "No flake.nix found. Shell initialization Aborted." 
                export PS1="‼️Shell uninitialized ‼️"
              fi
            else
              echo "Nested nix-shell detected, skipping init"
            fi
          '';
        };
      }
    );
}
