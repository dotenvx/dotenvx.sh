#!/bin/sh

set -e

# default values
VERSION="0.44.1"
DIRECTORY="/usr/local/bin"

usage() {
  echo "Usage: $0 [options] [command]"
  echo ""
  echo "install dotenvx – a better dotenv"
  echo ""
  echo "Options:"
  echo "  --directory       directory to install dotenvx to (default: \"/usr/local/bin\")"
  echo "  --version         version of dotenvx to install (default: \"$VERSION\")"
  echo ""
  echo "Commands:"
  echo "  install           install dotenvx"
  echo "  help              display help"
}

directory() {
  local dir=$DIRECTORY

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

is_directory_writable() {
  # check installation directory is writable
  if [ ! -w "$(directory)" ]; then
    echo "[INSTALLATION_FAILED] the installation directory [$(directory)] is not writable by the current user"
    echo "? run as root [sudo $0] or choose a writable directory like your current directory [$0 --directory=.]"

    return 1
  fi

  return 0
}

is_curl_installed() {
  if ! command -v curl >/dev/null 2>&1; then
    echo "[INSTALLATION_FAILED] curl is required and appears to not be installed"
    echo "? install curl and try again"

    return 1
  fi

  return 0
}

os() {
  echo "$(uname -s | tr '[:upper:]' '[:lower:]')"

  return 0
}

arch() {
  echo "$(uname -m | tr '[:upper:]' '[:lower:]')"

  return 0
}

is_os_supported() {
  local os="$(os)"

  case "$os" in
  linux) os="linux" ;;
  darwin) os="darwin" ;;
  *)
    echo "[INSTALLATION_FAILED] your operating system ${os} is currently unsupported"
    echo "? request support by opening an issue at [https://github.com/dotenvx/dotenvx.sh/issues]"

    return 1
    ;;
  esac

  return 0
}

is_arch_supported() {
  local arch="$(arch)"

  case "$arch" in
  x86_64) arch="x86_64" ;;
  amd64) arch="amd64" ;;
  arm64) arch="arm64" ;;
  aarch64) arch="aarch64" ;;
  *)
    echo "[INSTALLATION_FAILED] your architecture ${arch} is currently unsupported - must be x86_64, amd64, arm64, or aarch64"
    echo "? request support by opening an issue at [https://github.com/dotenvx/dotenvx.sh/issues]"

    return 1
    ;;
  esac

  return 0
}

os_arch() {
  echo "$(os)-$(arch)"

  return 0
}

filename() {
  echo "dotenvx-$VERSION-$(os_arch).tar.gz"

  return 0
}

download_url() {
  echo "https://github.com/dotenvx/dotenvx/releases/download/v$VERSION/$(filename)"

  return 0
}

is_ci() {
  [ -n "$CI" ] && [ $CI != 0 ]
}

progress_bar() {
  if $(is_ci); then
    echo "--no-progress-meter"
  else
    echo "--progress-bar"
  fi

  return 0
}

which_dotenvx() {
  local result
  result=$(command which dotenvx 2>/dev/null) # capture the output without displaying it on the screen

  echo "$result"

  return 0
}

warn_of_any_conflict() {
  local dotenvx_path="$(which_dotenvx)"

  if [ "$dotenvx_path" != "" ] && [ "$dotenvx_path" != "$(directory)/dotenvx" ]; then
    echo "[DOTENVX_CONFLICT] conflicting dotenvx found at $dotenvx_path" >&2
    echo "? we recommend updating your path to include $(directory)" >&2
  fi

  return 0
}

is_installed() {
  local flagged_version="$1"
  local current_version=$("$(directory)/dotenvx" --version 2>/dev/null || echo "0")

  # if --version flag passed
  if [ -n "$flagged_version" ]; then
    if [ "$current_version" = "$flagged_version" ]; then
      # return true since version already installed
      return 0
    else
      # return false since version not installed
      return 1
    fi
  fi

  # if no version flag passed
  if [ "$current_version" != "$VERSION" ]; then
    # return false since latest is not installed
    return 1
  fi

  echo "[dotenvx@$current_version] already installed ($(directory)/dotenvx)"

  # return true since version already installed
  return 0
}

install_dotenvx() {
  # 0. override version
  VERSION="${1:-$VERSION}"

  # 1. setup tmpdir
  local tmpdir=$(command mktemp -d)

  # 2. download
  curl $(progress_bar) --fail -L --proto '=https' -o "$tmpdir/$(filename)" "$(download_url)"

  # 3. decompress to install directory
  tar xz -C $(directory) -f "$tmpdir/$(filename)"

  # 4. clean up
  rm -r "$tmpdir"

  # warn of any conflict
  warn_of_any_conflict

  # let user know
  echo "[dotenvx@$VERSION] installed successfully ($(directory)/dotenvx)"

  return 0
}

main() {
  # parse arguments
  for arg in "$@"; do
    case $arg in
    version=* | --version=*)
      VERSION="${arg#*=}"
      ;;
    directory=* | --directory=*)
      DIRECTORY="${arg#*=}"
      ;;
    help | --help)
      usage
      return 0
      ;;
    *)
      # Unknown option
      echo "Unknown option: $arg"
      usage
      return 1
      ;;
    esac
  done

  is_directory_writable
  is_curl_installed
  is_os_supported
  is_arch_supported

  # install logic
  if [ -n "$VERSION" ]; then
    # Check if the specified version is already installed
    if is_installed "$VERSION"; then
      echo "[dotenvx@$VERSION] already installed ($(directory)/dotenvx)"

      return 0
    else
      install_dotenvx "$VERSION"
    fi
  else
    if is_installed; then
      echo "[dotenvx@$VERSION] already installed ($(directory)/dotenvx)"

      return 0
    else
      install_dotenvx
    fi
  fi
}

# execute main only if the script is run directly, not sourced
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  main "$@"
  exit $?
fi
