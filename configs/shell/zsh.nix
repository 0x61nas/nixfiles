{ pkgs, config, ... }:
{
  # Download the prompt
  home.file.".config/zsh/prompt.zsh".source = builtins.fetchurl {
    url = "https://gist.githubusercontent.com/0x61nas/6ee08add16a0ac8f63bfc485be5239f0/raw/72915834bb24398aae2968a96e0b350f5ff206b7/prompt.zsh";
    sha256 = "1kkaq2x3p6dvgjbsbq0ir9la5ffxxh1a5s288jpj64zkm529p4af";
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
	    name = "zsh-history-substring-search";
        src = "${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search";
        file = "zsh-history-substring-search.zsh";
	  }
	  {
	    name = "you-should-use";
        src = "${pkgs.zsh-you-should-use}/share/zsh/plugins/you-should-use";
        file = "you-should-use.plugin.zsh";
	  }
      {
        name = "nix-zsh-compltions";
        src = "${pkgs.nix-zsh-completions}/share/zsh/plugins/nix";
        file = "nix.plugin.zsh";
      }
      #{
        #name = "zsh-autoswitch-virtualenv";
        #src = pkgs.fetchFromGitHub {
          #owner = "archy-linux";
          #repo = "zsh-autoswitch-virtualenv";
          #rev = "master";
          #sha256 = "sha256-9ussStZVNwWkefWZDE3S9AXTVMEuwjoWLQ+MzYVCjm4=";
        #};
        #file = "autoswitch_virtualenv.plugin.zsh";
      #}
    ];
    initExtra = ''
      SHELL_NAME=$(basename $SHELL)
      DISABLE_AUTO_TITLE="false"
      ENABLE_CORRECTION="false"
      COMPLETION_WAITING_DOTS="true"
      source "$HOME/.config/zsh/prompt.zsh"
      [[ -e "$HOME/.private-env.sh" ]] && source "$HOME/.private-env.sh"
      [[ -e "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

      if command -v gh >/dev/null 2>&1; then
        eval "$(gh copilot alias -- $SHELL_NAME)"
      fi

      if command -v pyenv 1>/dev/null 2>&1; then
        eval "$(pyenv init -)"
      fi
      eval "$(${pkgs.zoxide}/bin/zoxide init $SHELL_NAME)"

          bindkey '^ ' autosuggest-accept
    ZSH_AUTOSUGGEST_STRATEGY=(history completion)

    # EXTRACT FUNCTION (needs more nix)

    hst() {
        history 0 | cut -c 8- | uniq | ${pkgs.fzf}/bin/fzf | ${pkgs.xclip}/bin/xclip
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
