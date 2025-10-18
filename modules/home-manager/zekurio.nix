{ pkgs, ... }:
{
  home = {
    username = "zekurio";
    homeDirectory = "/home/zekurio";
    stateVersion = "25.05";

    packages = with pkgs; [
      git
      btop
      neovim
      eza
      fzf
      starship
      zellij
      bat
    ];
  };

  # Fish shell configuration with Nord theme
  programs.fish = {
    enable = true;
    plugins = [
      {
        name = "eza";
        src = pkgs.fetchFromGitHub {
          owner = "oh-my-fish";
          repo = "plugin-eza";
          rev = "main";
          sha256 = "sha256-iKdz1eJqNfGrGfslWdv1FBKsJK9p8K8HfQ8Jnb6ZZvE=";
        };
      }
      {
        name = "nord";
        src = pkgs.fetchFromGitHub {
          owner = "oh-my-fish";
          repo = "theme-nord";
          rev = "master";
          sha256 = "sha256-2Ux8+tQ3dvJ+wjfLp3LU9BN9KzcZqLPUEbKbM6bbM30=";
        };
      }
    ];
    interactiveShellInit = ''
      # Initialize starship prompt
      starship init fish | source
      
      # Initialize fzf
      fzf --fish | source
      
      # Initialize zellij
      zellij setup --generate-completion fish | source
      
      # Set Nord theme
      fish_config theme choose nord
    '';
  };

  # Starship prompt configuration with Nord theme
  programs.starship = {
    enable = true;
    settings = {
      format = "$username$hostname$directory$git_branch$git_commit$git_state$git_status$cmd_duration$line_break$character";
      
      # Nord colors
      palette = "nord";
      palettes.nord = {
        nord0 = "#2e3440";
        nord1 = "#3b4252";
        nord2 = "#434c5e";
        nord3 = "#4c566a";
        nord4 = "#d8dee9";
        nord5 = "#e5e9f0";
        nord6 = "#eceff4";
        nord7 = "#8fbcbb";
        nord8 = "#88c0d0";
        nord9 = "#81a1c1";
        nord10 = "#5e81ac";
        nord11 = "#bf616a";
        nord12 = "#d08770";
        nord13 = "#ebcb8b";
        nord14 = "#a3be8c";
        nord15 = "#b48ead";
      };
      
      character = {
        success_symbol = "[➜](bold nord14)";
        error_symbol = "[✗](bold nord11)";
      };
      
      directory = {
        style = "bold nord8";
      };
      
      git_branch = {
        style = "bold nord9";
      };
      
      git_status = {
        style = "bold nord11";
      };
      
      username = {
        style_user = "bold nord7";
        show_always = false;
      };
      
      hostname = {
        style = "bold nord8";
        ssh_only = true;
        ssh_symbol = "🌐 ";
      };
    };
  };

  # fzf configuration with Nord theme
  programs.fzf = {
    enable = true;
    defaultCommand = "fd --type f";
    defaultOptions = [
      "--height 40%"
      "--reverse"
      "--color=bg+:#2e3440,bg:#eceff4,spinner:#81a1c1,hl:#d08770"
      "--color=fg:#4c566a,header:#d08770,info:#88c0d0,marker:#81a1c1"
      "--color=fg+:#2e3440,prompt:#81a1c1,hl+:#d08770"
    ];
  };

  # bat (cat replacement) configuration with Nord theme
  programs.bat = {
    enable = true;
    config = {
      theme = "Nord";
    };
  };

  # Environment variables
  home.sessionVariables = {
    EDITOR = "nvim";
    FZF_DEFAULT_COMMAND = "fd --type f";
    FZF_CTRL_T_COMMAND = "fd --type f";
  };
}
