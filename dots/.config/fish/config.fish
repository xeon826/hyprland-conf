function fish_prompt -d "Write out the prompt"
    # This shows up as USER@HOST /home/user/ >, with the directory colored
    # $USER and $hostname are set by fish, so you can just use them
    # instead of using `whoami` and `hostname`
    printf '%s@%s %s%s%s > ' $USER $hostname \
        (set_color $fish_color_cwd) (prompt_pwd) (set_color normal)
end

if status is-interactive # Commands to run in interactive sessions can go here

    # No greeting
    set fish_greeting

    # Use starship
    starship init fish | source
    if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
        cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
    end

    # Aliases
    alias pamcan pacman
    alias ls 'eza --icons'
    alias clear "printf '\033[2J\033[3J\033[1;1H'"
    alias q 'qs -c ii'

    # PATH exports
    fish_add_path /snap/bin
    fish_add_path $HOME/.cargo/bin
    fish_add_path $HOME/.local/bin
    fish_add_path $HOME/.luarocks/bin
    fish_add_path $HOME/.config/composer/vendor/bin
    fish_add_path $HOME/.config/herd-lite/bin
    fish_add_path $HOME/bin
    fish_add_path $HOME/go/bin

    # Environment variables
    set -gx LC_ALL en_US.UTF-8
    set -gx LANG en_US.UTF-8
    set -gx LANGUAGE en_US.UTF-8
    set -gx FONTCONFIG_PATH /etc/fonts
    set -gx PASSWORD_STORE_DIR ~/.password-store
    set -gx BROWSER /usr/bin/firefox
    set -gx EDITOR vim
    set -gx SDL_GAMECONTROLLERCONFIG "030072264c050000e60c000000016800,PS5 Controller new mapping,a:b0,b:b1,x:b2,y:b3,back:b4,guide:b15,start:b6,leftshoulder:b9,rightshoulder:b10,leftstick:b7,rightstick:b8,dpup:b11,dpleft:b13,dpdown:b12,dpright:b14,leftx:a0,lefty:a1,rightx:a2,righty:a3,lefttrigger:a4,righttrigger:a5,platform:Linux,"
    set -gx VAGRANT_DISABLE_STRICT_DEPENDENCY_ENFORCEMENT 1
    set -gx LESS -R
    set -gx ANDROID_SDK_ROOT $HOME/Android/Sdk
    set -gx LIBVIRT_DEFAULT_URI "qemu:///system"
    set -gx TERM xterm-kitty
    set -gx SILLYTAVERN_LISTEN true
    set -gx SILLYTAVERN_PORT 8002
    set -gx PYTORCH_CUDA_ALLOC_CONF expandable_segments:True
    set -gx PHP_INI_SCAN_DIR "$HOME/.config/herd-lite/bin:$PHP_INI_SCAN_DIR"
    set -gx DOCKER_BUILDKIT 1
    set -gx PHP_CS_FIXER_IGNORE_ENV 1
    set -gx ENV dev
    set -gx SPARK_HOME ~/.local/spark
    set -gx KAFKA_HOME ~/.local/kafka
    set -gx DRILL_HOME ~/.local/drill
    set -gx AIRFLOW_HOME ~/airflow
    set -gx AIRFLOW__WEBSERVER__WEB_SERVER_PORT 8081
    set -gx ZEPPELIN_HOME ~/.local/zeppelin
    set -gx ANTHROPIC_BASE_URL https://api.deepseek.com/anthropic
    set -gx API_TIMEOUT_MS 600000
    set -gx ANTHROPIC_MODEL deepseek-chat
    set -gx ANTHROPIC_SMALL_FAST_MODEL deepseek-chat
    set -gx CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC 1

    # Add tool-specific paths
    fish_add_path $ANDROID_SDK_ROOT/emulator
    fish_add_path $ANDROID_SDK_ROOT/tools
    fish_add_path $ANDROID_SDK_ROOT/tools/bin
    fish_add_path $ANDROID_SDK_ROOT/platform-tools
    fish_add_path $SPARK_HOME/bin
    fish_add_path $SPARK_HOME/sbin
    fish_add_path $KAFKA_HOME/bin
    fish_add_path $DRILL_HOME/bin
    fish_add_path $ZEPPELIN_HOME/bin

    # FZF configuration
    set -gx FZF_DEFAULT_OPTS "$FZF_DEFAULT_OPTS \
      --highlight-line \
      --info=inline-right \
      --ansi \
      --layout=reverse \
      --border=none \
      --color=bg+:#283457 \
      --color=bg:#16161e \
      --color=border:#27a1b9 \
      --color=fg:#c0caf5 \
      --color=gutter:#16161e \
      --color=header:#ff9e64 \
      --color=hl+:#2ac3de \
      --color=hl:#2ac3de \
      --color=info:#545c7e \
      --color=marker:#ff007c \
      --color=pointer:#ff007c \
      --color=prompt:#2ac3de \
      --color=query:#c0caf5:regular \
      --color=scrollbar:#27a1b9 \
      --color=separator:#ff9e64 \
      --color=spinner:#ff007c \
      --color=fg:#ffffff,bg:#161616,hl:#08bdba \
      --color=fg+:#f2f4f8,bg+:#262626,hl+:#3ddbd9 \
      --color=info:#78a9ff,prompt:#33b1ff,pointer:#42be65 \
      --color=marker:#ee5396,spinner:#ff7eb6,header:#be95ff"

    # Functions
    function activate
        set -l search_dir "."
        if test (count $argv) -gt 0
            set search_dir $argv[1]
        end
        source (find "$search_dir" -iname "activate" | head -1)
    end

    function start
        set -l search_dir "."
        if test (count $argv) -gt 0
            set search_dir $argv[1]
        end
        set -l original_dir (pwd)

        # Find the closest devbox.json file
        set -l devbox_dir (dirname (find "$search_dir" -name "devbox.json" | head -1))

        if test -n "$devbox_dir"
            cd "$devbox_dir"
            source (find . -iname "start" | head -1)
            cd "$original_dir"
        else
            source (find "$search_dir" -iname "start" | head -1)
        end
    end

    function brightness
        xrandr --output DP-1 --brightness $argv[1] && xrandr --output DP-2 --brightness $argv[1]
    end

    # Key bindings
    bind \cg 'lazygit'
    bind \cn 'nvim'
    bind \cl 'claude'
    bind \cb 'cd ..'
    bind \cf 'ranger'

    # Tool initializations
    if test -d "$HOME/.nvm"
        set -gx NVM_DIR "$HOME/.nvm"
    end

    if test -d "$HOME/.pyenv"
        set -gx PYENV_ROOT "$HOME/.pyenv"
        fish_add_path $PYENV_ROOT/bin
        pyenv init - | source
        pyenv virtualenv-init - | source
    end

    if test -f "$HOME/Downloads/google-cloud-sdk/path.fish.inc"
        source "$HOME/Downloads/google-cloud-sdk/path.fish.inc"
    end

    if test -f "$HOME/Downloads/google-cloud-sdk/completion.fish.inc"
        source "$HOME/Downloads/google-cloud-sdk/completion.fish.inc"
    end

    # Source aliases file
    if test -f ~/.config/fish/aliases.fish
        source ~/.config/fish/aliases.fish
    end

    # SDKMAN
    set -gx SDKMAN_DIR "$HOME/.sdkman"
    if test -f "$HOME/.sdkman/bin/sdkman-init.fish"
        source "$HOME/.sdkman/bin/sdkman-init.fish"
    end

    # FZF key bindings and fuzzy completion
    fzf --fish | source

    # Zoxide
    zoxide init fish | source

    # Conda (if installed)
    if test -f "$HOME/miniconda3/etc/fish/conf.d/conda.fish"
        source "$HOME/miniconda3/etc/fish/conf.d/conda.fish"
    else if test -d "$HOME/miniconda3/bin"
        fish_add_path "$HOME/miniconda3/bin"
    end

end


