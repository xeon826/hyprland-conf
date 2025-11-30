# This script is meant to be sourced.
# It's not for directly running.
# Symlink-based file installation - creates symlinks instead of copying files

printf "${STY_CYAN}[$0]: 3. Installing config files via symlinks\n${STY_RST}"

# shellcheck shell=bash

function warning_overwrite(){
  printf "${STY_YELLOW}"
  printf "The command below will overwrite the destination.\n"
  printf "${STY_RST}"
}

function auto_backup_configs(){
  local backup=false
  case $ask in
    false) if [[ ! -d "$BACKUP_DIR" ]]; then local backup=true;fi;;
    *)
      printf "${STY_RED}"
      printf "Would you like to backup clashing dirs/files to \"$BACKUP_DIR\"?\n"
      printf "${STY_RST}"
      while true;do
        echo "  y = Yes, backup"
        echo "  n/s = No, skip to next"
        local p; read -p "====> " p
        case $p in
          [yY]) echo -e "${STY_BLUE}OK, doing backup...${STY_RST}"
            local backup=true;break ;;
          [nNsS]) echo -e "${STY_BLUE}Alright, skipping...${STY_RST}"
            local backup=false;break ;;
          *) echo -e "${STY_RED}Please enter [y/n/s].${STY_RST}";;
        esac
      done
      ;;
  esac
  if $backup;then
    backup_clashing_targets dots/.config $XDG_CONFIG_HOME "${BACKUP_DIR}/.config"
    backup_clashing_targets dots/.local/share $XDG_DATA_HOME "${BACKUP_DIR}/.local/share"
    printf "${STY_BLUE}Backup into \"${BACKUP_DIR}\" finished.${STY_RST}\n"
  fi
}

function gen_firstrun(){
  x mkdir -p "$(dirname ${FIRSTRUN_FILE})"
  x touch "${FIRSTRUN_FILE}"
  x mkdir -p "$(dirname ${INSTALLED_LISTFILE})"
  realpath -se "${FIRSTRUN_FILE}" >> "${INSTALLED_LISTFILE}"
}

# Symlink functions
symlink_file(){
  # NOTE: This function is only for using in other functions
  local source_file="$1"
  local target_file="$2"

  # Get absolute path to source
  local abs_source="$(realpath -se "$source_file")"

  x mkdir -p "$(dirname "$target_file")"

  # Remove existing file/directory if it exists
  if [ -e "$target_file" ]; then
    if [ -L "$target_file" ]; then
      # It's already a symlink, remove it
      x rm "$target_file"
    elif [ -f "$target_file" ] || [ -d "$target_file" ]; then
      # It's a real file/directory, back it up
      echo -e "${STY_YELLOW}[$0]: Backing up existing \"$target_file\" to \"$target_file.backup\"${STY_RST}"
      x mv "$target_file" "$target_file.backup"
    fi
  fi

  # Create the symlink
  x ln -sf "$abs_source" "$target_file"

  # Track installed symlinks
  x mkdir -p "$(dirname ${INSTALLED_LISTFILE})"
  realpath -se "$target_file" >> "${INSTALLED_LISTFILE}"
  echo -e "${STY_GREEN}[$0]: Created symlink: \"$target_file\" -> \"$abs_source\"${STY_RST}"
}

symlink_dir(){
  # NOTE: This function is only for using in other functions
  local source_dir="$1"
  local target_dir="$2"

  # Get absolute path to source
  local abs_source="$(realpath -se "$source_dir")"

  x mkdir -p "$(dirname "$target_dir")"

  # Remove existing directory if it exists
  if [ -e "$target_dir" ]; then
    if [ -L "$target_dir" ]; then
      # It's already a symlink, remove it
      x rm "$target_dir"
    elif [ -d "$target_dir" ]; then
      # It's a real directory, back it up
      echo -e "${STY_YELLOW}[$0]: Backing up existing \"$target_dir\" to \"$target_dir.backup\"${STY_RST}"
      x mv "$target_dir" "$target_dir.backup"
    fi
  fi

  # Create the symlink
  x ln -sf "$abs_source" "$target_dir"

  # Track installed symlinks
  x mkdir -p "$(dirname ${INSTALLED_LISTFILE})"
  realpath -se "$target_dir" >> "${INSTALLED_LISTFILE}"
  echo -e "${STY_GREEN}[$0]: Created symlink: \"$target_dir\" -> \"$abs_source\"${STY_RST}"
}

function install_file_symlink(){
  # NOTE: Do not add prefix `v` or `x` when using this function
  local s=$1
  local t=$2
  if [ -f "$t" ] || [ -d "$t" ]; then
    warning_overwrite
  fi
  v symlink_file "$s" "$t"
}

function install_dir_symlink(){
  # NOTE: Do not add prefix `v` or `x` when using this function
  local s=$1
  local t=$2
  if [ -d "$t" ]; then
    warning_overwrite
  fi
  v symlink_dir "$s" "$t"
}

#####################################################################################
# In case some dirs does not exists
for i in "$XDG_BIN_HOME" "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME"; do
  if ! test -e "$i"; then
    v mkdir -p "$i"
  fi
done

case "${INSTALL_FIRSTRUN}" in
  # When specify --firstrun
  true) sleep 0 ;;
  # When not specify --firstrun
  *)
    if test -f "${FIRSTRUN_FILE}"; then
      INSTALL_FIRSTRUN=false
    else
      INSTALL_FIRSTRUN=true
    fi
    ;;
esac

showfun auto_update_git_submodule
v auto_update_git_submodule

# Backup
if [[ ! "${SKIP_BACKUP}" == true ]]; then auto_backup_configs; fi

#####################################################################################
# MISC (For dots/.config/* but not quickshell, not fish, not Hyprland, not fontconfig)
case "${SKIP_MISCCONF}" in
  true) sleep 0;;
  *)
    for i in $(find dots/.config/ -mindepth 1 -maxdepth 1 ! -name 'quickshell' ! -name 'fish' ! -name 'hypr' ! -name 'fontconfig' -exec basename {} \;); do
      echo "[$0]: Found target: dots/.config/$i"
      if [ -d "dots/.config/$i" ];then install_dir_symlink "dots/.config/$i" "$XDG_CONFIG_HOME/$i"
      elif [ -f "dots/.config/$i" ];then install_file_symlink "dots/.config/$i" "$XDG_CONFIG_HOME/$i"
      fi
    done
    install_dir_symlink "dots/.local/share/konsole" "${XDG_DATA_HOME}"/konsole
    ;;
esac

case "${SKIP_QUICKSHELL}" in
  true) sleep 0;;
  *)
     # Should overwriting the whole directory not only ~/.config/quickshell/ii/ cuz https://github.com/end-4/dots-hyprland/issues/2294#issuecomment-3448671064
    install_dir_symlink dots/.config/quickshell "$XDG_CONFIG_HOME"/quickshell
    ;;
esac

case "${SKIP_FISH}" in
  true) sleep 0;;
  *)
    install_dir_symlink dots/.config/fish "$XDG_CONFIG_HOME"/fish
    ;;
esac

case "${SKIP_FONTCONFIG}" in
  true) sleep 0;;
  *)
    case "$FONTSET_DIR_NAME" in
      "") install_dir_symlink dots/.config/fontconfig "$XDG_CONFIG_HOME"/fontconfig ;;
      *) install_dir_symlink dots-extra/fontsets/$FONTSET_DIR_NAME "$XDG_CONFIG_HOME"/fontconfig ;;
    esac;;
esac

# For Hyprland
case "${SKIP_HYPRLAND}" in
  true) sleep 0;;
  *)
    install_dir_symlink dots/.config/hypr/hyprland "$XDG_CONFIG_HOME"/hypr/hyprland
    install_dir_symlink dots/.config/hypr/custom "$XDG_CONFIG_HOME"/hypr/custom
    for i in hypr{land,lock}.conf {monitors,workspaces}.conf ; do
      install_file_symlink "dots/.config/hypr/$i" "${XDG_CONFIG_HOME}/hypr/$i"
    done
    for i in hypridle.conf ; do
      if [[ "${INSTALL_VIA_NIX}" == true ]]; then
        install_file_symlink "dots-extra/via-nix/$i" "${XDG_CONFIG_HOME}/hypr/$i"
      else
        install_file_symlink "dots/.config/hypr/$i" "${XDG_CONFIG_HOME}/hypr/$i"
      fi
    done
    if [ "$OS_GROUP_ID" = "fedora" ];then
      v bash -c "printf \"# For fedora to setup polkit\nexec-once = /usr/libexec/kf6/polkit-kde-authentication-agent-1\n\" >> ${XDG_CONFIG_HOME}/hypr/hyprland/execs.conf"
    fi
    ;;
esac

install_file_symlink "dots/.local/share/icons/illogical-impulse.svg" "${XDG_DATA_HOME}"/icons/illogical-impulse.svg

#####################################################################################

v gen_firstrun
v dedup_and_sort_listfile "${INSTALLED_LISTFILE}" "${INSTALLED_LISTFILE}"

# Prevent hyprland from not fully loaded
sleep 1
try hyprctl reload

#####################################################################################
printf "\n"
printf "\n"
printf "\n"
printf "${STY_CYAN}[$0]: Finished${STY_RST}\n"
printf "\n"
printf "${STY_CYAN}When starting Hyprland from your display manager (login screen) ${STY_RED} DO NOT SELECT UWSM ${STY_RST}\n"
printf "\n"
printf "${STY_CYAN}If you are already running Hyprland,${STY_RST}\n"
printf "${STY_CYAN}Press ${STY_INVERT} Ctrl+Super+T ${STY_RST}${STY_CYAN} to select a wallpaper${STY_RST}\n"
printf "${STY_CYAN}Press ${STY_INVERT} Super+/ ${STY_RST}${STY_CYAN} for a list of keybinds${STY_RST}\n"
printf "\n"
printf "${STY_CYAN}For suggestions/hints after installation:${STY_RST}\n"
printf "${STY_CYAN}${STY_UNDERLINE} https://ii.clsty.link/en/ii-qs/01setup/#post-installation ${STY_RST}\n"
printf "\n"

if [[ -z "${ILLOGICAL_IMPULSE_VIRTUAL_ENV}" ]]; then
  printf "\n${STY_RED}[$0]: \!! Important \!! : Please ensure environment variable ${STY_RST} \$ILLOGICAL_IMPULSE_VIRTUAL_ENV ${STY_RED} is set to proper value (by default \"~/.local/state/quickshell/.venv\"), or Quickshell config will not work. We have already provided this configuration in ~/.config/hypr/hyprland/env.conf, but you need to ensure it is included in hyprland.conf, and also a restart is needed for applying it.${STY_RST}\n"
fi