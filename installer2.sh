#!/bin/sh

set -e

# default values
VERSION="0.44.1"
INSTALLATION_DIRECTORY="/usr/local/bin"

usage() {
  echo "Usage: $0 [options] [command]"
  echo ""
  echo "install dotenvx – a better dotenv"
  echo ""
  echo "Options:"
  echo "  --path            set the installation directory, default is /usr/local/bin"
  echo "  --version         set the version of dotenvx to install, for example: --version=0.44.1"
  echo ""
  echo "Commands:"
  echo "  install           install dotenvx"
  echo "  help              display help"
}

installation_directory() {
  local dir=$INSTALLATION_DIRECTORY

  case "$dir" in
  ~*/*)
    dir="$HOME/${dir#\~/}"
    ;;
  ~*)
    dir="$HOME/${dir#\~}"
    ;;
  esac

  echo "${dir}"
  return 0
}

is_installation_directory_writable() {
  # check installation directory is writable
  if [ ! -w "$(installation_directory)" ] && [ "$(id -u)" -ne 0 ]; then
    echo "[INSTALLATION_FAILED] the installation directory [$(installation_directory)] is not writable by the current user"
    echo "? run as root [sudo $0] or choose a writable directory like your current directory [$0 path=.]"

    return 1
  fi

  return 0
}

# parse arguments
for arg in "$@"; do
  case $arg in
  path=* | --path=*)
    INSTALLATION_DIRECTORY="${arg#*=}"
    ;;
  help | --help)
    usage
    exit 0
    ;;
  *)
    # Unknown option
    echo "Unknown option: $arg"
    usage
    exit 1
    ;;
  esac
done

echo "success"
