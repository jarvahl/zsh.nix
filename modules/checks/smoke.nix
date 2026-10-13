{ config, inputs, lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      zshrc = config.flake.lib.zshConfiguration {
        inherit pkgs;
        modules = [{ initConfig = "export NIX_ZSH_SMOKE=42"; }];
      };
      attrsetApiZsh = config.flake.lib.zshConfiguration {
        inherit pkgs;
        modules = [
          {
            vi.enable = true;
            autosuggestion.enable = true;
            syntaxHighlighting.integrations.patina.enable = true;

            completion = {
              enable = true;
              integrations.fzf.enable = true;
            };

            history.integrations.fzf.enable = true;

            aliases = {
              ll = "ls -l";
              gs = "git status";
            };
          }
        ];
      };
      completionFzfWithoutCompletion = config.flake.lib.zshConfiguration {
        inherit pkgs;
        modules = [
          {
            completion.integrations.fzf.enable = true;
          }
        ];
      };
      completionFzfWithoutCompletionEval = builtins.tryEval completionFzfWithoutCompletion.drvPath;
      homeManagerIntegration = import "${inputs.home-manager}/modules" {
        inherit pkgs;
        configuration = {
          imports = [ config.flake.homeManagerModules.default ];

          home.homeDirectory = "/tmp/nzf-smoke";
          home.stateVersion = "25.11";
          home.username = "nzf-smoke";

          programs.nzf = {
            enable = true;
            settings.zsh.aliases.ll = "ls -l";
          };

          programs.zsh.initContent = lib.mkAfter ''
            echo after
          '';
        };
      };
      zdotdir = pkgs.runCommand "zdotdir" { } "mkdir -p $out && cp ${zshrc}/.zshrc $out/.zshrc";
      zsh = pkgs.symlinkJoin {
        name = "nix-zsh-smoke";
        paths = [ pkgs.zsh ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = "wrapProgram $out/bin/zsh --set ZDOTDIR ${zdotdir}";
        meta.mainProgram = "zsh";
      };
    in
    {
      checks.smoke = pkgs.runCommand "nix-zsh-smoke" { nativeBuildInputs = [ pkgs.zsh ]; } ''
        export HOME="$(mktemp -d)"
        output=$(${lib.getExe zsh} -i -c 'print -- "RESULT=$NIX_ZSH_SMOKE"' 2>/dev/null)
        echo "$output" | grep -q '^RESULT=42$'
        touch $out
      '';

      checks.attrset-api = pkgs.runCommand "nix-zsh-attrset-api" { } ''
        zshrc=${attrsetApiZsh}/.zshrc

        grep -q 'autoload -Uz compinit' "$zshrc"
        grep -q '^compinit$' "$zshrc"
        grep -q "^alias ll='ls -l'$" "$zshrc"
        grep -q "^alias gs='git status'$" "$zshrc"
        grep -q 'zsh-vi-mode.plugin.zsh' "$zshrc"
        grep -q 'zsh-autosuggestions.zsh' "$zshrc"
        grep -q 'zsh-patina activate' "$zshrc"
        grep -q 'fzf-tab.plugin.zsh' "$zshrc"
        grep -q 'zsh-fzf-history-search.plugin.zsh' "$zshrc"
        line() {
          grep -n "$1" "$zshrc" | head -n1 | cut -d: -f1
        }

        test "$(line 'zsh-vi-mode.plugin.zsh')" -lt "$(line 'zsh-autosuggestions.zsh')"
        test "$(line 'zsh-autosuggestions.zsh')" -lt "$(line 'zsh-patina activate')"
        test "$(line 'fzf-tab.plugin.zsh')" -lt "$(line 'zsh-fzf-history-search.plugin.zsh')"
        touch $out
      '';

      checks.completion-fzf-requires-completion =
        pkgs.runCommand "nix-zsh-completion-fzf-requires-completion" { } ''
          if ${lib.boolToString completionFzfWithoutCompletionEval.success}; then
            echo "expected completion.integrations.fzf.enable without completion.enable to fail evaluation"
            exit 1
          fi

          touch $out
        '';

      checks.home-manager-integration = pkgs.runCommand "nzf-home-manager-integration" { } ''
        initContent=${pkgs.writeText "nzf-zsh-init" homeManagerIntegration.config.programs.zsh.initContent}

        ${lib.optionalString (!homeManagerIntegration.config.programs.zsh.enable) ''
          echo "expected programs.nzf.enable to enable programs.zsh by default"
          exit 1
        ''}

        grep -q "^alias ll='ls -l'$" "$initContent"
        grep -q 'echo after' "$initContent"

        line() {
          grep -n "$1" "$initContent" | head -n1 | cut -d: -f1
        }

        test "$(line "^alias ll='ls -l'$")" -lt "$(line 'echo after')"

        touch $out
      '';
    };
}
