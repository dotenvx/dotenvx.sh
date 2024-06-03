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
  if [ ! -w "$(directory)" ] && [ "$(id -u)" -ne 0 ]; then
    echo "[INSTALLATION_FAILED] the installation directory [$(directory)] is not writable by the current user"
    echo "? run as root [sudo $0] or choose a writable directory like your current directory [$0 directory=.]"

    return 1
  fi

  return 0
}

is_curl_installed() {
  if ! command -v curl >/dev/null 2>&1; then
    echo "[INSTALLATION_FAILED] curl is required and appears to not be installed"
    echo "? install curl and try again"

    exit 1
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

version() {
  echo "$VERSION"

  return 0
}

filename() {
  echo "dotenvx-$(version)-$(os_arch).tar.gz"

  return 0
}

download_url() {
  echo "https://github.com/dotenvx/dotenvx/releases/download/v$(version)/$(filename)"

  return 0
}

is_ci() {
  [ -n "$CI" ] && [ $CI != 0 ]
}

# parse arguments
for arg in "$@"; do
  case $arg in
  directory=* | --directory=*)
    DIRECTORY="${arg#*=}"
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

is_directory_writable
is_curl_installed
is_os_supported
is_arch_supported

# echo "os: $(os) arch: $(arch)"
echo "hello"
