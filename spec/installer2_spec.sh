Describe 'installer2.sh'
  Include installer2.sh

  setup() {
    VERSION="0.44.1"
    INSTALLATION_DIRECTORY="/usr/local/bin"
  }

  mock_home() {
    HOME="/home/testuser"
    INSTALLATION_DIRECTORY="~/testdir"
  }

  mock_writable_directory() {
    INSTALLATION_DIRECTORY="$(pwd)/tmp/"
  }

  BeforeEach 'setup'

  Describe 'default values'
    It 'checks default VERSION'
      When call echo "$VERSION"
      The output should equal "0.44.1"
    End

    It 'checks default INSTALLATION_DIRECTORY'
      When call echo "$INSTALLATION_DIRECTORY"
      The output should equal "/usr/local/bin"
    End
  End

  Describe 'installation_directory()'
    It 'smartly returns installation_directory as default INSTALL_DIR'
      When call installation_directory
      The output should equal "/usr/local/bin"
    End

    Describe 'when home directory'
      Before 'mock_home'

      It 'expands ~ to home directory'
        When call installation_directory
        The output should equal "/home/testuser/testdir"
      End
    End
  End

  Describe 'is_installation_directory_writable()'
    It 'is false (1) to /usr/local/bin (typical case that /usr/local/bin is not writable)'
      When call is_installation_directory_writable
      The status should equal 1
      The output should equal "[INSTALLATION_FAILED] the installation directory [/usr/local/bin] is not writable by the current user
? run as root [sudo /bin/sh] or choose a writable directory like your current directory [/bin/sh path=.]"
    End

    Describe 'when writable directory'
      Before 'mock_writable_directory'

      It 'is true (0)'
        When call is_installation_directory_writable
        The status should equal 0
      End
    End
  End

  Describe 'usage()'
    It 'displays usage'
      When call usage
      The output should equal "Usage: /bin/sh [options] [command]

install dotenvx – a better dotenv

Options:
  --path            set the installation directory, default is /usr/local/bin
  --version         set the version of dotenvx to install, for example: --version=0.44.1

Commands:
  install           install dotenvx
  help              display help"
    End
  End
End
