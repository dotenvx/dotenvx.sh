#!/bin/sh

set -e

if test -n "$VERBOSE" -o -n "$GITHUB_ACTIONS" -a -n "$RUNNER_DEBUG"; then
  set -x
fi

_install_pre_reqs() {
  if test -f /etc/debian_version; then
    apt update --yes

    case $(cat /etc/debian_version) in
    jessie/sid|8.*|stretch/sid|9.*)
      apt --yes install sudo;;
    buster/sid|10.*)
      apt --yes install sudo;;
    bullseye/sid|11.*)
      apt --yes install sudo;;
    bookworm/sid|12.*|*)
      apt --yes install sudo;;
    esac
  fi
}

_install_pre_reqs

if test -d /usr/local/bin -a ! -w /usr/local/bin; then
  SUDO="sudo"
elif test -d /usr/local -a ! -w /usr/local; then
  SUDO="sudo"
elif test -d /usr -a ! -w /usr; then
  SUDO="sudo"
fi

_is_ci() {
  [ -n "$CI" ] && [ $CI != 0 ]
}

_install_dotenvx() {
  if _is_ci; then
    progress="--no-progress-meter"
  else
    progress="--progress-bar"
  fi

  tmpdir=$(mktemp -d)

  if [ $# -eq 0 ]; then
    if [ -f /usr/local/bin/dotenvx ]; then
      echo "upgrading: /usr/local/bin/dotenvx" >&2
    else
      echo "installing: /usr/local/bin/dotenvx" >&2
    fi

    # using a named pipe to prevent curl progress output trumping the sudo password prompt
    pipe="$tmpdir/pipe"
    mkfifo "$pipe"

    curl $progress --fail --proto '=https' "https://dotenvx.sh/$(uname)/$(uname -m)".tgz > "$pipe" &
    $SUDO sh -c "
      mkdir -p /usr/local/bin
      tar xz --directory /usr/local/bin < '$pipe'
    " &
    wait

    rm -r "$tmpdir"

    if [ "$(command which dotenvx)" != /usr/local/bin/dotenvx ]; then
      echo "warning: active dotenvx is not /usr/local/bin/dotenvx" >&2
      export PATH="/usr/local/bin:$PATH"  # so we can exec if required
    fi

    # tell the user what version we just installed
    dotenvx --version

  else
    curl $progress --fail --proto '=https' \
        "https://dotenvx.sh/$(uname)/$(uname -m)".tgz \
      | tar xz --directory "$tmpdir"

    export PATH="$tmpdir:$PATH"
    export DOTENVX_DIR="$tmpdir"
  fi

  unset tmpdir pipe
}

_dotenvx_is_old() {
  v="$(/usr/local/bin/dotenvx --version || echo dotenvx 0)"
  /usr/local/bin/dotenvx --silent semverator gt \
    $(curl -Ssf https://dotenvx.sh/VERSION) \
    $(echo $v | awk '{print $2}')
}

_should_install_dotenvx() {
  if [ ! -f /usr/local/bin/dotenvx ]; then
    return 0
  elif _dotenvx_is_old >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

########################################################################### meat

if _should_install_dotenvx; then
  _install_dotenvx "$@"
elif [ $# -eq 0 ]; then
  echo "$(dotenvx --version) already installed" >&2
fi

if _is_ci; then
  apt() {
    # we should use apt-get not apt in CI
    # weird shit ref: https://askubuntu.com/a/668859
    export DEBIAN_FRONTEND=noninteractive
    cmd=$1
    shift
    $SUDO apt-get $cmd -qq -o=Dpkg::Use-Pty=0 $@
  }
else
  apt() {
    case "$1" in
    update)
      echo "ensure you have the `dotenvx` pre-requisites installed:" >&2
      echo >&2
      ;;
    install)
      echo "   apt-get" "$@" >&2
      ;;
    esac
  }
  yum() {
    echo "   yum" "$@" >&2
  }
  unset SUDO
fi

if [ $# -gt 0 ]; then
  dotenvx "$@"
elif [ $(basename "/$0") != 'installer.sh' ]; then
  # ^^ temporary exception for action.ts

  # if type eval >/dev/null 2>&1; then
  #   # we `type eval` as on Travis there was no `eval`!
  #   eval "$(dotenvx --shellcode)" 2>/dev/null
  # fi

  if ! _is_ci; then
    echo "now type: dotenvx help" >&2
  fi
fi
