Describe 'install.sh'
  # source the script without executing it immediately
  . ./install.sh

  setup() {
    VERSION="0.44.1"
    DIRECTORY="./spec/tmp"
    CI=1
  }

  # remove the dotenvx binary before each test
  cleanup() {
    rm -f ./spec/tmp/dotenvx
  }

  mock_home() {
    HOME="/home/testuser"
    DIRECTORY="~/testdir"
  }

  mock_unwritable_directory() {
    DIRECTORY="/usr/local/testing-installer" # requires root/sudo
  }

  mock_which_dotenvx_empty() {
    echo ""

    return 0
  }

  mock_which_dotenvx_path_different() {
    echo "/different/path"

    return 0
  }

  preinstall_dotenvx() {
    # Run the actual install_dotenvx function to install the binary
    install_dotenvx
  }

  BeforeEach 'setup'
  BeforeEach 'cleanup'
  AfterEach 'cleanup'

  Describe 'default values'
    It 'checks default VERSION'
      When call echo "$VERSION"
      The output should equal "0.44.1"
    End

    It 'checks default DIRECTORY'
      When call echo "$DIRECTORY"
      The output should equal "./spec/tmp"
    End
  End

  Describe 'usage()'
    It 'displays usage'
      When call usage
      The output should equal "Usage: $0 [options] [command]

install dotenvx – a better dotenv

Options:
  --directory       directory to install dotenvx to (default: \"/usr/local/bin\")
  --version         version of dotenvx to install (default: \"0.44.1\")

Commands:
  install           install dotenvx
  help              display help"
    End
  End

  Describe 'directory()'
    It 'smartly returns directory as default INSTALL_DIR'
      When call directory
      The output should equal "./spec/tmp"
    End

    Describe 'when home directory'
      Before 'mock_home'

      It 'expands ~ to home directory'
        When call directory
        The output should equal "/home/testuser/testdir"
      End
    End
  End

  Describe 'is_directory_writable()'
    It 'is true (0)'
      When call is_directory_writable
      The status should equal 0
    End

    Describe 'when unwritable directory'
      Before 'mock_unwritable_directory'

      It 'is false (1) to /usr/local/testing-installer (typical case that /usr/local/testing-installer is not writable)'
        When call is_directory_writable
        The status should equal 1
        The output should equal "[INSTALLATION_FAILED] the installation directory [/usr/local/testing-installer] is not writable by the current user
? run as root [sudo $0] or choose a writable directory like your current directory [$0 --directory=.]"
      End
    End
  End

  Describe 'is_curl_installed()'
    It 'is true (0) (typical case that /usr/bin/curl is installed)'
      When call is_curl_installed
      The status should equal 0
    End
  End

  Describe 'os()'
    It 'returns current os lowercased'
      When call os
      The status should equal 0
      The output should equal "$(uname -s | tr '[:upper:]' '[:lower:]')"
    End
  End

  Describe 'arch()'
    It 'returns current arch lowercased'
      When call arch
      The status should equal 0
      The output should equal "$(uname -m | tr '[:upper:]' '[:lower:]')"
    End
  End

  Describe 'is_os_supported()'
    It 'returns true'
      When call is_os_supported
      The status should equal 0
    End
  End

  Describe 'is_arch_supported()'
    It 'returns true'
      When call is_arch_supported
      The status should equal 0
    End
  End

  Describe 'os_arch()'
    It 'returns the combined values'
      When call os_arch
      The status should equal 0
      The output should equal "$(uname -s | tr '[:upper:]' '[:lower:]')-$(uname -m | tr '[:upper:]' '[:lower:]')"
    End
  End

  Describe 'filename()'
    It 'returns the combined values'
      When call filename
      The status should equal 0
      The output should equal "dotenvx-0.44.1-$(uname -s | tr '[:upper:]' '[:lower:]')-$(uname -m | tr '[:upper:]' '[:lower:]').tar.gz"
    End
  End

  Describe 'download_url()'
    It 'returns the combined values'
      When call download_url
      The status should equal 0
      The output should equal "https://github.com/dotenvx/dotenvx/releases/download/v0.44.1/dotenvx-0.44.1-$(uname -s | tr '[:upper:]' '[:lower:]')-$(uname -m | tr '[:upper:]' '[:lower:]').tar.gz"
    End
  End

  Describe 'is_installed()'
    It 'returns false'
      When call is_installed
      The status should equal 1
    End

    Describe 'when already installed'
      Before 'preinstall_dotenvx'

      It 'returns true'
        When call is_installed
        The status should equal 0
      End
    End
  End

  Describe 'which_dotenvx()'
    which_dotenvx() {
      mock_which_dotenvx_empty
    }

    It 'returns empty space'
      When call which_dotenvx
      The output should equal ""
    End

    Describe 'when a different path'
      which_dotenvx() {
        mock_which_dotenvx_path_different
      }

      It 'returns the different path'
        When call which_dotenvx
        The output should equal "/different/path"
      End
    End
  End

  Describe 'warn_of_any_conflict()'
    which_dotenvx() {
      mock_which_dotenvx_empty
    }

    It 'does not warn since which dotenvx is empty'
      When call warn_of_any_conflict
      The status should equal 0
      The stderr should equal ""
      The output should equal ""
    End

    Describe 'when a different path'
      which_dotenvx() {
        mock_which_dotenvx_path_different
      }

      It 'warns'
        When call warn_of_any_conflict
        The status should equal 0
        The stderr should equal "[DOTENVX_CONFLICT] conflicting dotenvx found at /different/path
? we recommend updating your path to include ./spec/tmp"
      End
    End
  End

  Describe 'install_dotenvx()'
    # which_dotenvx() {
    #   mock_which_dotenvx_empty
    # }

    # It 'installs it'
    #   When call install_dotenvx
    #   The status should equal 0
    #   The output should equal "[dotenvx@0.44.1] installed successfully (./spec/tmp/dotenvx)"
    # End

    # Describe 'when a different path'
    #   which_dotenvx() {
    #     mock_which_dotenvx_path_different
    #   }

    #   It 'installs it but warns'
    #     When call install_dotenvx
    #     The status should equal 0
    #   The output should equal "[dotenvx@0.44.1] installed successfully (./spec/tmp/dotenvx)"
    #     The stderr should equal "[DOTENVX_CONFLICT] conflicting dotenvx found at /different/path
# ? we#  recommend updating your path to include ./spec/tmp"
    #   End
    # End

    Describe 'when already installed at same location'
      which_dotenvx() {
        mock_which_dotenvx_empty
      }

      Before 'preinstall_dotenvx'

      It 'says already installed'
        When call install_dotenvx
        The status should equal 0
        The output should equal "[dotenvx@0.44.1] already installed (./spec/tmp/dotenvx)"
      End
    End
  End
End
