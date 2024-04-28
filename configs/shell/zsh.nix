{lib, pkgs, ... }:
{
  # Download the prompt
  home.file.".config/zsh/prompt.zsh".source = builtins.fetchurl {
    url = "https://gist.githubusercontent.com/0x61nas/6ee08add16a0ac8f63bfc485be5239f0/raw/100a7fecc752b6fe0ce564124a3c1e660ce18b7a/prompt.zsh";
    sha256 = "0cl2ml4z62yiwn0n5wk6bj4zsf5avjl643c66k2p0m2bfa8a2pwk";
  };
  
  programs.zsh = {
    enable = true;
    dotDir = ".config/zsh";
    syntaxHighlighting.enable = true;
    enableAutosuggestions = true;
    enableCompletion = true;
    autocd = true;
    history = {
	save = 5000;
	path = "~/.shell_history";
	expireDuplicatesFirst = true;
	share = true;
    };
    plugins = [
	  {
	    # will source zsh-autosuggestions.plugin.zsh
	    name = "zsh-autosuggestions";
	    src = pkgs.fetchFromGitHub {
	      owner = "zsh-users";
	      repo = "zsh-autosuggestions";
	      rev = "v0.7.0";
	      sha256 = "sha256-KLUYpUu4DHRumQZ3w59m9aTW6TBKMCXl2UcKi4uMd7w=";
	    };
	  }
	  {
	    name = "zsh-syntax-highlighting";
	    src = pkgs.fetchFromGitHub {
	      owner = "zsh-users";
	      repo = "zsh-syntax-highlighting";
	      rev = "0.8.0";
	      sha256 = "sha256-iJdWopZwHpSyYl5/FQXEW7gl/SrKaYDEtTH9cGP7iPo=";
	    };
	  }
	  {
	    name = "zsh-history-substring-search";
	    src = pkgs.fetchFromGitHub {
	      owner = "zsh-users";
	      repo = "zsh-history-substring-search";
	      rev = "v1.1.0";
	      sha256 = "sha256-GSEvgvgWi1rrsgikTzDXokHTROoyPRlU0FVpAoEmXG4=";
	    };
	  }
	  {
	    name = "zsh-you-should-use";
	    src = pkgs.fetchFromGitHub {
	      owner = "MichaelAquilina";
	      repo = "zsh-you-should-use";
	      rev = "1.7.3";
	      sha256 = "sha256-/uVFyplnlg9mETMi7myIndO6IG7Wr9M7xDFfY1pG5Lc=";
	    };
	  }
	  {
	    name = "zsh-autoswitch-virtualenv";
	    src = pkgs.fetchFromGitHub {
	      owner = "archy-linux";
	      repo = "zsh-autoswitch-virtualenv";
	      rev = "master";
	      sha256 = "sha256-9ussStZVNwWkefWZDE3S9AXTVMEuwjoWLQ+MzYVCjm4=";
	    };
	  }
	  {
	    name = "zsh-auto-notify";
	    src = pkgs.fetchFromGitHub {
	      owner = "archy-linux";
	      repo = "zsh-auto-notify";
	      rev = "master";
	      sha256 = "sha256-11VyO65GEP8yvXsLNktNmC2yn5WT+301rEKKOx94g3M=";
	    };
	  }
    ];
    initExtra = ''
      SHELL_NAME=$(basename $SHELL)
      DISABLE_AUTO_TITLE="false"
      ENABLE_CORRECTION="false"
      COMPLETION_WAITING_DOTS="true"
      source "$HOME/.config/zsh/prompt.zsh"
      [[ -e "$HOME/.private-env.sh" ]] && source "$HOME/.private-env.sh"

      if command -v gh >/dev/null 2>&1; then
        eval "$(gh copilot alias -- $SHELL_NAME)"
      fi

      if command -v pyenv 1>/dev/null 2>&1; then
        eval "$(pyenv init -)"
      fi
      eval "$(zoxide init $SHELL_NAME)"
    '';

    completionInit = ''
      zstyle ':completion:*' menu select
      zstyle ':completion:*' accept-exact '*(N)'
      zstyle ':completion:*' use-cache on
      zstyle ':completion:*' cache-path ~/.zsh/cache
    '';
  };
  
}
