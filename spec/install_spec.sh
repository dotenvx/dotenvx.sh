Describe 'install.sh'
  Include install.sh directory=./spec/tmp

  setup() {
    VERSION="0.44.1"
  }

  mock_home() {
    HOME="/home/testuser"
    DIRECTORY="~/testdir"
  }

  mock_unwritable_directory() {
    DIRECTORY="/usr/local/testing-installer" # requires root/sudo
  }

  BeforeEach 'setup'

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
End
