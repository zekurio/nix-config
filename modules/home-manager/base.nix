{
  lib,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.homeManager.base;
in {
  options.modules.homeManager.base = {
    enable =
      mkEnableOption "Base user account and shell configuration"
      // {
        default = true;
      };
  };

  config = mkIf cfg.enable {
    home-manager.users.zekurio = {pkgs, ...}: {
      home.username = "zekurio";
      home.homeDirectory = "/home/zekurio";
      home.stateVersion = "25.05";
      home.enableNixpkgsReleaseCheck = false;

      home.packages = with pkgs; [
        # CLI utilities
        bat
        btop
        eza
        pfetch
        jq
        envsubst
        zellij
        # Version control
        git
        # Nix tools
        nil
        nixd
        sops
        age
      ];

      programs.fish = {
        enable = true;
        interactiveShellInit = ''
          set -g fish_greeting
        '';
      };

      programs.eza = {
        enable = true;
        extraOptions = ["--group-directories-first" "--icons=auto"];
      };

      programs.starship = {
        enable = true;
        enableFishIntegration = true;
        settings = {
          add_newline = true;
          continuation_prompt = "[▸▹ ](dimmed white)";
          format = "($nix_shell$container$fill$git_metrics\n)$cmd_duration$hostname$localip$shlvl$shell$env_var$jobs$sudo$username$character";
          right_format = "$singularity\n$kubernetes\n$directory\n$vcsh\n$fossil_branch\n$git_branch\n$git_commit\n$git_state\n$git_status\n$hg_branch\n$pijul_channel\n$docker_context\n$package\n$c\n$cpp\n$cmake\n$cobol\n$daml\n$dart\n$deno\n$dotnet\n$elixir\n$elm\n$erlang\n$fennel\n$fortran\n$golang\n$guix_shell\n$haskell\n$haxe\n$helm\n$java\n$julia\n$kotlin\n$gradle\n$lua\n$nim\n$nodejs\n$ocaml\n$opa\n$perl\n$php\n$pulumi\n$purescript\n$python\n$raku\n$rlang\n$red\n$ruby\n$rust\n$scala\n$solidity\n$swift\n$terraform\n$vlang\n$vagrant\n$xmake\n$zig\n$buf\n$conda\n$pixi\n$meson\n$spack\n$memory_usage\n$aws\n$gcloud\n$openstack\n$azure\n$crystal\n$custom\n$status\n$os\n$battery\n$time";
          fill = {
            symbol = " ";
          };
          character = {
            format = "$symbol ";
            success_symbol = "[◎](bold italic bright-yellow)";
            error_symbol = "[○](italic purple)";
            vimcmd_symbol = "[■](italic dimmed green)";
            # not supported in zsh
            vimcmd_replace_one_symbol = "◌";
            vimcmd_replace_symbol = "□";
            vimcmd_visual_symbol = "▼";
          };
          env_var = {
            VIMSHELL = {
              format = "[$env_value]($style)";
              style = "green italic";
            };
          };
          sudo = {
            format = "[$symbol]($style)";
            style = "bold italic bright-purple";
            symbol = "⋈┈";
            disabled = false;
          };
          username = {
            style_user = "bright-yellow bold italic";
            style_root = "purple bold italic";
            format = "[⭘ $user]($style) ";
            disabled = false;
            show_always = false;
          };
          directory = {
            home_symbol = "⌂";
            truncation_length = 2;
            truncation_symbol = "□ ";
            read_only = " ◈";
            use_os_path_sep = true;
            style = "italic blue";
            format = "[$path]($style)[$read_only]($read_only_style)";
            repo_root_style = "bold blue";
            repo_root_format = "[$before_root_path]($before_repo_root_style)[$repo_root]($repo_root_style)[$path]($style)[$read_only]($read_only_style) [△](bold bright-blue)";
          };
          cmd_duration = {
            format = "[◄ $duration ](italic white)";
          };
          jobs = {
            format = "[$symbol$number]($style) ";
            style = "white";
            symbol = "[▶](blue italic)";
          };
          localip = {
            ssh_only = true;
            format = " ◯[$localipv4](bold magenta)";
            disabled = false;
          };
          time = {
            disabled = false;
            format = "[ $time]($style)";
            time_format = "%R";
            utc_time_offset = "local";
            style = "italic dimmed white";
          };
          battery = {
            format = "[ $percentage $symbol]($style)";
            full_symbol = "█";
            charging_symbol = "[↑](italic bold green)";
            discharging_symbol = "↓";
            unknown_symbol = "░";
            empty_symbol = "▃";
            display = [
              {
                threshold = 20;
                style = "italic bold red";
              }
              {
                threshold = 60;
                style = "italic dimmed bright-purple";
              }
              {
                threshold = 70;
                style = "italic dimmed yellow";
              }
            ];
          };
          git_branch = {
            format = " [$branch(:$remote_branch)]($style)";
            symbol = "[△](bold italic bright-blue)";
            style = "italic bright-blue";
            truncation_symbol = "⋯";
            truncation_length = 11;
            ignore_branches = ["main" "master"];
            only_attached = true;
          };
          git_metrics = {
            format = "([▴$added]($added_style))([▿$deleted]($deleted_style))";
            added_style = "italic dimmed green";
            deleted_style = "italic dimmed red";
            ignore_submodules = true;
            disabled = false;
          };
          git_status = {
            style = "bold italic bright-blue";
            format = "([⎪$ahead_behind$staged$modified$untracked$renamed$deleted$conflicted$stashed⎥]($style))";
            conflicted = "[◪◦](italic bright-magenta)";
            ahead = "[▴│[\${count}](bold white)│](italic green)";
            behind = "[▿│[\${count}](bold white)│](italic red)";
            diverged = "[◇ ▴┤[\${ahead_count}](regular white)│▿┤[\${behind_count}](regular white)│](italic bright-magenta)";
            untracked = "[◌◦](italic bright-yellow)";
            stashed = "[◃◈](italic white)";
            modified = "[●◦](italic yellow)";
            staged = "[▪┤[\${count}](bold white)│](italic bright-cyan)";
            renamed = "[◎◦](italic bright-blue)";
            deleted = "[✕](italic red)";
          };
          deno = {
            format = " [deno](italic) [∫ $version](green bold)";
            version_format = "\${raw}";
          };
          lua = {
            format = " [lua](italic) [\${symbol}\${version}]($style)";
            version_format = "\${raw}";
            symbol = "⨀ ";
            style = "bold bright-yellow";
          };
          nodejs = {
            format = " [node](italic) [◫ ($version)](bold bright-green)";
            version_format = "\${raw}";
            detect_files = ["package-lock.json" "yarn.lock"];
            detect_folders = ["node_modules"];
            detect_extensions = [];
          };
          python = {
            format = " [py](italic) [\${symbol}\${version}]($style)";
            symbol = "[⌉](bold bright-blue)⌊ ";
            version_format = "\${raw}";
            style = "bold bright-yellow";
          };
          ruby = {
            format = " [rb](italic) [\${symbol}\${version}]($style)";
            symbol = "◆ ";
            version_format = "\${raw}";
            style = "bold red";
          };
          rust = {
            format = " [rs](italic) [$symbol$version]($style)";
            symbol = "⊃ ";
            version_format = "\${raw}";
            style = "bold red";
          };
          package = {
            format = " [pkg](italic dimmed) [$symbol$version]($style)";
            version_format = "\${raw}";
            symbol = "◨ ";
            style = "dimmed yellow italic bold";
          };
          swift = {
            format = " [sw](italic) [\${symbol}\${version}]($style)";
            symbol = "◁ ";
            style = "bold bright-red";
            version_format = "\${raw}";
          };
          aws = {
            disabled = true;
            format = " [aws](italic) [$symbol $profile $region]($style)";
            style = "bold blue";
            symbol = "▲ ";
          };
          buf = {
            symbol = "■ ";
            format = " [buf](italic) [$symbol $version $buf_version]($style)";
          };
          c = {
            symbol = "ℂ ";
            format = " [$symbol($version(-$name))]($style)";
          };
          cpp = {
            symbol = "ℂ ";
            format = " [$symbol($version(-$name))]($style)";
          };
          conda = {
            symbol = "◯ ";
            format = " conda [$symbol$environment]($style)";
          };
          pixi = {
            symbol = "■ ";
            format = " pixi [$symbol$version ($environment )]($style)";
          };
          dart = {
            symbol = "◁◅ ";
            format = " dart [$symbol($version )]($style)";
          };
          docker_context = {
            symbol = "◧ ";
            format = " docker [$symbol$context]($style)";
          };
          elixir = {
            symbol = "△ ";
            format = " exs [$symbol $version OTP $otp_version ]($style)";
          };
          elm = {
            symbol = "◩ ";
            format = " elm [$symbol($version )]($style)";
          };
          golang = {
            symbol = "∩ ";
            format = " go [$symbol($version )]($style)";
          };
          haskell = {
            symbol = "❯λ ";
            format = " hs [$symbol($version )]($style)";
          };
          java = {
            symbol = "∪ ";
            format = " java [\${symbol}(\${version} )]($style)";
          };
          julia = {
            symbol = "◎ ";
            format = " jl [$symbol($version )]($style)";
          };
          memory_usage = {
            symbol = "▪▫▪ ";
            format = " mem [\${ram}( \${swap})]($style)";
          };
          nim = {
            symbol = "▴▲▴ ";
            format = " nim [$symbol($version )]($style)";
          };
          nix_shell = {
            style = "bold italic dimmed blue";
            symbol = "✶";
            format = "[$symbol nix⎪$state⎪]($style) [$name](italic dimmed white)";
            impure_msg = "[⌽](bold dimmed red)";
            pure_msg = "[⌾](bold dimmed green)";
            unknown_msg = "[◌](bold dimmed yellow)";
          };
          spack = {
            symbol = "◇ ";
            format = " spack [$symbol$environment]($style)";
          };
        };
      };
    };
  };
}
