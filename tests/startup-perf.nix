{ config, lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      zshrc = config.flake.lib.zshConfiguration {
        inherit pkgs;
        modules = [
          ({ config, ... }: {
            options.zsh.perf-plugins.enable = lib.mkEnableOption "perf-plugins";
            config = lib.mkIf config.zsh.perf-plugins.enable {
              zsh.startPlugins.start = {
                package = pkgs.writeTextDir "eager.zsh" "";
              };
              zsh.optPlugins.opt = {
                package = pkgs.writeTextDir "idle.zsh" "";
                init = "sleep 0.1";
              };
            };
          })
          {
            zsh.perf-plugins.enable = true;
            initConfig = ''
              autoload -Uz add-zsh-hook
              nix_zsh_first_prompt_ready() {
                print -r -- "NIX_ZSH_READY $(date +%s%N)"
                exit 0
              }
              add-zsh-hook precmd nix_zsh_first_prompt_ready
              PROMPT='> '
            '';
          }
        ];
      };
      zdotdir = pkgs.runCommand "zdotdir" { } "mkdir -p $out && cp ${zshrc}/.zshrc $out/.zshrc";
      zsh = pkgs.symlinkJoin {
        name = "nix-zsh-perf";
        paths = [ pkgs.zsh ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = "wrapProgram $out/bin/zsh --set ZDOTDIR ${zdotdir}";
        meta.mainProgram = "zsh";
      };
    in
    {
      checks.startup-perf = pkgs.runCommand "nix-zsh-startup-perf"
        {
          nativeBuildInputs = [
            pkgs.util-linux
            pkgs.zsh
          ];
        }
        ''
          export HOME="$(mktemp -d)"
          export LC_ALL=C
          durations_file="$(mktemp)"
          trap 'rm -rf "$HOME" "$durations_file"' EXIT
          runs=10
          threshold_ms=150
          run_once() {
            start_ns="$(date +%s%N)"
            output="$(timeout 5 script -qfec "${lib.getExe zsh} -i" /dev/null 2>&1)"
            ready_ns="$(echo "$output" | grep -o 'NIX_ZSH_READY [0-9]*' | tail -n 1 | cut -d' ' -f2)"
            if [ -n "$ready_ns" ] && [ "$ready_ns" -gt "$start_ns" ]; then
              echo "$(( (ready_ns - start_ns) / 1000000 ))"
            else
              echo "FAIL: ready_ns was $ready_ns, start_ns was $start_ns"
              exit 1
            fi
          }
          for _ in $(seq 1 $runs); do
            run_once >> "$durations_file"
          done
          median_ms="$(sort -n "$durations_file" | sed -n '5p')"
          echo "Median startup time: $median_ms ms (threshold: $threshold_ms ms)"
          if [ "$median_ms" -gt "$threshold_ms" ]; then
            echo "Performance regression!"
            exit 1
          fi
          touch $out
        '';
    };
}
