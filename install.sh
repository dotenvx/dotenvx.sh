#!/bin/sh
#  ___________________________________________________________________________________________________
#  |      _                                                                                          |
#  |     | |     | |                                                                                 |
#  |   __| | ___ | |_ ___ _ ____   ____  __                                                          |
#  |  / _` |/ _ \| __/ _ \ '_ \ \ / /\ \/ /                                                          |
#  | | (_| | (_) | ||  __/ | | \ V /  >  <                                                           |
#  |  \__,_|\___/ \__\___|_| |_|\_/  /_/\_\                                                          |
#  |                                                                                                 |
#  |                                                                                                 |
#  |  *a better dotenv*–from the creator of [`dotenv`](https://github.com/motdotla/dotenv).          |
#  |                                                                                                 |
#  |  * run anywhere (cross-platform)                                                                |
#  |  * multi-environment                                                                            |
#  |  * encrypted envs                                                                               |
#  |                                                                                                 |
#  |  ## Install                                                                                     |
#  |                                                                                                 |
#  |  ```sh                                                                                          |
#  |  curl https://dotenvx.sh/install.sh | sh                                                        |
#  |  ```                                                                                            |
#  |                                                                                                 |
#  |  or self-execute this file:                                                                     |
#  |                                                                                                 |
#  |  ```sh                                                                                          |
#  |  curl https://dotenvx.sh/install.sh > install.sh                                                |
#  |  chmod +x install.sh                                                                            |
#  |  ./install.sh                                                                                   |
#  |  ```                                                                                            |
#  |                                                                                                 |
#  |  ## Usage                                                                                       |
#  |                                                                                                 |
#  |  ```sh                                                                                          |
#  |  $ echo "HELLO=World" > .env                                                                    |
#  |  $ echo "console.log('Hello ' + process.env.HELLO)" > index.js                                  |
#  |                                                                                                 |
#  |  $ node index.js                                                                                |
#  |  Hello undefined # without dotenvx                                                              |
#  |                                                                                                 |
#  |  $ dotenvx run -- node index.js                                                                 |
#  |  Hello World # with dotenvx                                                                     |
#  |  ```                                                                                            |
#  |                                                                                                 |
#  |  see [`dotenvx`](https://github.com/dotenvx/dotenvx) for extended usage guides.                 |
#  |                                                                                                 |
#  |_________________________________________________________________________________________________|

set -e
VERSION="0.44.1"
DIRECTORY="/usr/local/bin"
RELEASES_URL="https://github.com/dotenvx/dotenvx/releases"

# usage
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
  local curl_path="$(which_curl)"

  if [ -z "$curl_path" ]; then
    echo "[INSTALLATION_FAILED] curl is required and is not installed"
    echo "? install curl [$(install_curl_command)] and try again"

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
    echo "? request support by opening an issue at [https://github.com/dotenvx/dotenvx/issues]"

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
    echo "? request support by opening an issue at [https://github.com/dotenvx/dotenvx/issues]"

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
  echo "$RELEASES_URL/download/v$VERSION/$(filename)"

  return 0
}

is_ci() {
  [ -n "$CI" ] && [ $CI != 0 ]
}

is_test_mode() {
  [ -n "$TEST_MODE" ] && [ $TEST_MODE != 0 ]
}

progress_bar() {
  if $(is_ci); then
    echo "--no-progress-meter"
  else
    echo "--progress-bar"
  fi

  return 0
}

install_curl_command() {
  if command -v apt-get >/dev/null 2>&1; then
    echo "sudo apt-get update && sudo apt-get install -y curl"
  elif command -v yum >/dev/null 2>&1; then
    echo "sudo yum install -y curl"
  elif command -v brew >/dev/null 2>&1; then
    echo "brew install curl"
  elif command -v pkg >/dev/null 2>&1; then
    echo "sudo pkg install curl"
  else
    echo "install curl manually"
  fi

  return 0
}

which_curl() {
  local result
  result=$(command -v curl 2>/dev/null) # capture the output without displaying it on the screen

  echo "$result"

  return 0
}

which_dotenvx() {
  local result
  result=$(command -v dotenvx 2>/dev/null) # capture the output without displaying it on the screen

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

if ! is_test_mode; then
  main "$@"
  exit $?
fi
