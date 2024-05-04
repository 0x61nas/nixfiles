{lib, pkgs, config, ... }:
{
  # Download the prompt
  home.file.".config/zsh/prompt.zsh".source = builtins.fetchurl {
    url = "https://gist.githubusercontent.com/0x61nas/6ee08add16a0ac8f63bfc485be5239f0/raw/100a7fecc752b6fe0ce564124a3c1e660ce18b7a/prompt.zsh";
    sha256 = "0cl2ml4z62yiwn0n5wk6bj4zsf5avjl643c66k2p0m2bfa8a2pwk";
  };

  home.file = {
    ".local/share/zsh/zsh-autosuggestions".source = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions";
    ".local/share/zsh/zsh-fast-syntax-highlighting".source = "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/site-functions";
    ".local/share/zsh/nix-zsh-completions".source = "${pkgs.nix-zsh-completions}/share/zsh/plugins/nix";
    ".local/share/zsh/zsh-vi-mode".source = "${pkgs.zsh-vi-mode}/share/zsh-vi-mode";
    ".local/share/zsh/you-should-use".source = "${pkgs.zsh-you-should-use}/share/zsh/plugins/you-should-use";
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
	path = "${config.home.homeDirectory}/.shell_history";
	expireDuplicatesFirst = true;
	share = true;
    };
    shellAliases = {
      nix-shell = "nix-shell --command zsh";
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
    # EXTRACT FUNCTION (needs more nix)

    hst() {
        history 0 | cut -c 8- | uniq | ${pkgs.fzf}/bin/fzf | ${pkgs.wl-clipboard}/bin/wl-copy
    }

    proj() {
      dir="$(cat ~/.local/share/direnv/allow/* | uniq | xargs dirname | ${pkgs.fzf}/bin/fzf --height 9)"
      cd "$dir"
    }
    bindkey -s '\eOP' 'proj\n'

    plf() {
      proj
      lf
    }

    detach() {
      prog=$1
      shift
      nohup setsid $prog $@ > /dev/null 2>&1
    }

    ex () {
      if [ -f $1 ] ; then
        case $1 in
          *.tar.bz2)   tar xjf $1   ;;
          *.tar.gz)    tar xzf $1   ;;
          *.bz2)       bunzip2 $1   ;;
          *.rar)       ${pkgs.unrar}/bin/unrar x $1   ;;
          *.gz)        gunzip $1    ;;
          *.tar)       tar xf $1    ;;
          *.tbz2)      tar xjf $1   ;;
          *.tgz)       tar xzf $1   ;;
          *.zip)       unzip $1     ;;
          *.Z)         uncompress $1;;
          *.7z)        7z x $1      ;;
          *.deb)       ar x $1      ;;
          *.tar.xz)    tar xf $1    ;;
          *.tar.zst)   tar xf $1    ;;
          *)           echo "'$1' cannot be extracted via ex()" ;;
        esac
      else
        echo "'$1' is not a valid file"
      fi
    }

    checkExtraDev()
    {
        [ -z ''${extra_dev_shell} ] && return

        addspace=""
        [ ! -z ''${extra_packages} ] && addspace=" "
        echo "$extra_dev_shell$addspace"
    }

    # PLUGINS (whatever)
    [ -f "$HOME/.local/share/zsh/zsh-vi-mode/zsh-vi-mode.plugin.zsh" ] && \
    source "$HOME/.local/share/zsh/zsh-vi-mode/zsh-vi-mode.plugin.zsh"

    [ -f "$HOME/.local/share/zsh/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" ] && \
    source "$HOME/.local/share/zsh/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"

    bindkey '^ ' autosuggest-accept
    ZSH_AUTOSUGGEST_STRATEGY=(history completion)
    

    [ -f "$HOME/.local/share/zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && \
    source "$HOME/.local/share/zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"

    [ -f "$HOME/.local/share/zsh/nix-zsh-completions/nix.plugin.zsh" ] && \
    source "$HOME/.local/share/zsh/nix-zsh-completions/nix.plugin.zsh"

    [ -f "$HOME/share/zsh/plugins/zsh-you-should-use/you-should-use.plugin.zsh" ] && \
    source "$HOME/share/zsh/plugins/zsh-you-should-use/you-should-use.plugin.zsh"

    if [[ -n $CUSTOMZSHTOSOURCE ]]; then
      source "$CUSTOMZSHTOSOURCE"
    fi

    chpwdf() {
        if env | grep -q direnv; then
            extra_dev_shell="direnv"
        else
            if [[ "$extra_dev_shell" = "direnv" ]]; then
                unset extra_dev_shell
            fi
        fi
    }

    chpwd_functions+=(chpwdf)
  '';

    completionInit = ''
      zstyle ':completion:*' menu select
      zstyle ':completion:*' accept-exact '*(N)'
      zstyle ':completion:*' use-cache on
      zstyle ':completion:*' cache-path ~/.zsh/cache
    '';
  };
  
}
