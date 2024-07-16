#!/usr/bin/env bash

{ # this ensures the entire script is downloaded #

tms_has() {
  type "$1" > /dev/null 2>&1
}

tms_echo() {
  command printf %s\\n "$*" 2>/dev/null
}

if [ -z "${BASH_VERSION}" ] || [ -n "${ZSH_VERSION}" ]; then
  # shellcheck disable=SC2016
  tms_echo >&2 'Error: the install instructions explicitly say to pipe the install script to `bash`; please follow them'
  exit 1
fi

tms_default_install_dir() {
  [ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.tms" || printf %s "${XDG_CONFIG_HOME}/tms"
}

tms_install_dir() {
  if [ -n "$tms_DIR" ]; then
    printf %s "${tms_DIR}"
  else
    tms_default_install_dir
  fi
}

tms_latest_version() {
  tms_echo "v0.0.1"
}

tms_source() {
  tms_echo "https://github.com/mylhyz/tms.git"
}

tms_try_profile() {
  if [ -z "${1-}" ] || [ ! -f "${1}" ]; then
    return 1
  fi
  tms_echo "${1}"
}

tms_detect_profile() {
  if [ "${PROFILE-}" = '/dev/null' ]; then
    # the user has specifically requested NOT to have tms touch their profile
    return
  fi

  if [ -n "${PROFILE}" ] && [ -f "${PROFILE}" ]; then
    tms_echo "${PROFILE}"
    return
  fi

  local DETECTED_PROFILE
  DETECTED_PROFILE=''

  if [ "${SHELL#*bash}" != "$SHELL" ]; then
    if [ -f "$HOME/.bashrc" ]; then
      DETECTED_PROFILE="$HOME/.bashrc"
    elif [ -f "$HOME/.bash_profile" ]; then
      DETECTED_PROFILE="$HOME/.bash_profile"
    fi
  elif [ "${SHELL#*zsh}" != "$SHELL" ]; then
    if [ -f "$HOME/.zshrc" ]; then
      DETECTED_PROFILE="$HOME/.zshrc"
    elif [ -f "$HOME/.zprofile" ]; then
      DETECTED_PROFILE="$HOME/.zprofile"
    fi
  fi

  if [ -z "$DETECTED_PROFILE" ]; then
    for EACH_PROFILE in ".profile" ".bashrc" ".bash_profile" ".zprofile" ".zshrc"
    do
      if DETECTED_PROFILE="$(tms_try_profile "${HOME}/${EACH_PROFILE}")"; then
        break
      fi
    done
  fi

  if [ -n "$DETECTED_PROFILE" ]; then
    tms_echo "$DETECTED_PROFILE"
  fi
}

tms_profile_is_bash_or_zsh() {
  local TEST_PROFILE
  TEST_PROFILE="${1-}"
  case "${TEST_PROFILE-}" in
    *"/.bashrc" | *"/.bash_profile" | *"/.zshrc" | *"/.zprofile")
      return
    ;;
    *)
      return 1
    ;;
  esac
}

install_tms_from_git() {
  # 检查本地目录是否存在
  local INSTALL_DIR
  INSTALL_DIR="$(tms_install_dir)"
  local tms_VERSION
  tms_VERSION="${tms_INSTALL_VERSION:-$(tms_latest_version)}"

  local fetch_error
  if [ -d "$INSTALL_DIR/.git" ]; then
    # Updating repo
    tms_echo "=> tms is already installed in $INSTALL_DIR, trying to update using git"
    command printf '\r=> '
    fetch_error="Failed to update tms with $tms_VERSION, run 'git fetch' in $INSTALL_DIR yourself."
  else
    fetch_error="Failed to fetch origin with $tms_VERSION. Please report this!"
    tms_echo "=> Downloading tms from git to '$INSTALL_DIR'"
    command printf '\r=> '
    mkdir -p "${INSTALL_DIR}"
    if [ "$(ls -A "${INSTALL_DIR}")" ]; then
      # Initializing repo
      command git init "${INSTALL_DIR}" || {
        tms_echo >&2 'Failed to initialize tms repo. Please report this!'
        exit 2
      }
      command git --git-dir="${INSTALL_DIR}/.git" remote add origin "$(tms_source)" 2> /dev/null \
        || command git --git-dir="${INSTALL_DIR}/.git" remote set-url origin "$(tms_source)" || {
        tms_echo >&2 'Failed to add remote "origin" (or set the URL). Please report this!'
        exit 2
      }
    else
      # Cloning repo
      command git clone "$(tms_source)" --depth=1 "${INSTALL_DIR}" || {
        tms_echo >&2 'Failed to clone tms repo. Please report this!'
        exit 2
      }
    fi
  fi

  # 检出远程仓库到本地目录
  command git -c advice.detachedHead=false --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" checkout -f --quiet main || {
    tms_echo >&2 "Failed to checkout the given version $tms_VERSION. Please report this!"
    exit 2
  }
  if [ -n "$(command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" show-ref refs/heads/main)" ]; then
    if command git --no-pager --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" branch --quiet 2>/dev/null; then
      command git --no-pager --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" branch --quiet -D main >/dev/null 2>&1
    else
      tms_echo >&2 "Your version of git is out of date. Please update it!"
      command git --no-pager --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" branch -D main >/dev/null 2>&1
    fi
  fi

  # 清理仓库
  tms_echo "=> Compressing and cleaning up git repository"
  if ! command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" reflog expire --expire=now --all; then
    tms_echo >&2 "Your version of git is out of date. Please update it!"
  fi
  if ! command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" gc --auto --aggressive --prune=now ; then
    tms_echo >&2 "Your version of git is out of date. Please update it!"
  fi
  return
}

tms_do_install() {
    # 创建本地路径
    if [ -n "${tms_DIR-}" ] && ! [ -d "${tms_DIR}" ]; then
        if [ -e "${tms_DIR}" ]; then
            tms_echo >&2 "File \"${tms_DIR}\" has the same name as installation directory."
            exit 1
        fi

        if [ "${tms_DIR}" = "$(tms_default_install_dir)" ]; then
            mkdir "${tms_DIR}"
        else
            tms_echo >&2 "You have \$tms_DIR set to \"${tms_DIR}\", but that directory does not exist. Check your profile files and environment."
            exit 1
        fi
    fi

    if tms_has git; then
      install_tms_from_git
    else
      tms_echo >&2 'You need git to install tms'
      exit 1
    fi


    tms_echo

    local tms_PROFILE
    tms_PROFILE="$(tms_detect_profile)"
    local PROFILE_INSTALL_DIR
    PROFILE_INSTALL_DIR="$(tms_install_dir | command sed "s:^$HOME:\$HOME:")"

    SOURCE_STR="\\nexport tms_DIR=\"${PROFILE_INSTALL_DIR}\"\\n[ -s \"\$tms_DIR/tms.sh\" ] && \\. \"\$tms_DIR/tms.sh\"  # This loads tms\\n"

    # shellcheck disable=SC2016
    COMPLETION_STR='[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads tms bash_completion\n'
    BASH_OR_ZSH=false

    if [ -z "${tms_PROFILE-}" ] ; then
      local TRIED_PROFILE
      if [ -n "${PROFILE}" ]; then
        TRIED_PROFILE="${tms_PROFILE} (as defined in \$PROFILE), "
      fi
      tms_echo "=> Profile not found. Tried ${TRIED_PROFILE-}~/.bashrc, ~/.bash_profile, ~/.zprofile, ~/.zshrc, and ~/.profile."
      tms_echo "=> Create one of them and run this script again"
      tms_echo "   OR"
      tms_echo "=> Append the following lines to the correct file yourself:"
      command printf "${SOURCE_STR}"
      tms_echo
    else
      if tms_profile_is_bash_or_zsh "${tms_PROFILE-}"; then
        BASH_OR_ZSH=true
      fi
      if ! command grep -qc '/tms.sh' "$tms_PROFILE"; then
        tms_echo "=> Appending tms source string to $tms_PROFILE"
        command printf "${SOURCE_STR}" >> "$tms_PROFILE"
      else
        tms_echo "=> tms source string already in ${tms_PROFILE}"
      fi
      # shellcheck disable=SC2016
      if ${BASH_OR_ZSH} && ! command grep -qc '$NVM_DIR/bash_completion' "$tms_PROFILE"; then
        tms_echo "=> Appending bash_completion source string to $tms_PROFILE"
        command printf "$COMPLETION_STR" >> "$tms_PROFILE"
      else
        tms_echo "=> bash_completion source string already in ${tms_PROFILE}"
      fi
    fi
    if ${BASH_OR_ZSH} && [ -z "${tms_PROFILE-}" ] ; then
      tms_echo "=> Please also append the following lines to the if you are using bash/zsh shell:"
      command printf "${COMPLETION_STR}"
    fi

    # Source tms
    # shellcheck source=/dev/null
    \. "$(tms_install_dir)/tms.sh"

    tms_reset

    tms_echo "=> Close and reopen your terminal to start using tms or run the following to use it now:"
    command printf "${SOURCE_STR}"
    if ${BASH_OR_ZSH} ; then
      command printf "${COMPLETION_STR}"
    fi
}

tms_reset() {
  unset -f tms_has tms_install_dir tms_latest_version tms_profile_is_bash_or_zsh \
    tms_source install_tms_from_git \
    tms_try_profile tms_detect_profile \
    tms_do_install tms_reset tms_default_install_dir
}

tms_do_install

} # this ensures the entire script is downloaded #