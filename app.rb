# app.rb
require "sinatra"
require "open-uri"
require "fileutils"
require "tmpdir"

set :server, :puma
set :port, ENV["PORT"] || 3000

# Load install scripts, version files, and other assets at startup
INSTALL_SCRIPT = File.read(File.join(__dir__, "install.sh"))
VERSION = File.read(File.join(__dir__, "VERSION")).strip
GITHUB_RELEASES_URL = "https://github.com/dotenvx/dotenvx/releases/download"
ROBOTS = File.read(File.join(__dir__, "robots.txt")).strip
OPS_INSTALL_SCRIPT = begin
  File.read(File.join(__dir__, "ops/install.sh"))
rescue
  ""
end
OPS_VERSION = begin
  File.read(File.join(__dir__, "ops/VERSION")).strip
rescue
  "0.1.0"
end
ARMOR_INSTALL_SCRIPT = begin
  File.read(File.join(__dir__, "armor/install.sh"))
rescue
  ""
end
ARMOR_VERSION = begin
  File.read(File.join(__dir__, "armor/VERSION")).strip
rescue
  "0.1.0"
end
EXT_VAULT_INSTALL_SCRIPT = begin
  File.read(File.join(__dir__, "ext/vault/install.sh"))
rescue
  ""
end
EXT_VAULT_VERSION = begin
  File.read(File.join(__dir__, "ext/vault/VERSION")).strip
rescue
  "0.1.0"
end

helpers do
  def handle_download(os, arch, version = nil)
    arch = arch.gsub(/\.[^\/.]+$/, "").downcase.strip
    version = (version || VERSION).delete_prefix("v")

    halt 404 unless arch.match?(/\A[a-z0-9_]+\z/)
    halt 400, "Invalid version" unless version.match?(/\A\d+\.\d+\.\d+(?:-[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*)?\z/)

    filename = "dotenvx-#{version}-#{os}-#{arch}.tar.gz"
    url = "#{GITHUB_RELEASES_URL}/v#{version}/#{filename}"
    binary = (os == "windows") ? "dotenvx.exe" : "dotenvx"
    download_name = "dotenvx-#{os}-#{arch}-#{version}.tgz"
    directory = Dir.mktmpdir
    release_path = File.join(directory, filename)
    download_path = File.join(directory, download_name)

    fetched = system("curl", "-fsSL", "--proto", "=https", "--max-time", "60", "-o", release_path, url)
    halt 502, "Could not download release archive" unless fetched

    unpacked = system("tar", "-xzf", release_path, "-C", directory)
    halt 502, "Invalid release archive" unless unpacked && File.file?(File.join(directory, binary))

    File.chmod(0o755, File.join(directory, binary))
    packed = system({"COPYFILE_DISABLE" => "1"}, "tar", "--format", "ustar", "-czf", download_path, "-C", directory, binary)
    halt 500, "Could not package download" unless packed

    content_type "application/gzip"
    attachment download_name
    file = Rack::Files.new(directory, {"content-type" => "application/gzip"})
    status, file_headers, file_body = file.serving(request, download_path)
    download_body = Rack::BodyProxy.new(file_body) { FileUtils.remove_entry(directory) }
    halt status, file_headers, download_body
  ensure
    FileUtils.remove_entry(directory) if directory && !download_body
  end

  def format_number(num)
    case num
    when 1_000_000..Float::INFINITY
      "#{(num / 1_000_000.0).round(1)}M"
    when 1_000..999_999
      "#{(num / 1_000.0).round(1)}k"
    else
      num.to_s
    end
  end

  def handle_stats(packages)
    total_downloads = packages.sum do |pkg|
      response = URI.open("https://api.npmjs.org/downloads/point/last-year/#{pkg}")
      data = JSON.parse(response.read)
      data["downloads"]
    rescue
      0
    end

    {
      schemaVersion: 1,
      label: "downloads",
      message: format_number(total_downloads),
      color: "brightgreen"
    }.to_json
  end

  def handle_install(install_script, version = nil, directory = nil, os = nil, arch = nil, force = nil)
    result = install_script.dup
    result.gsub!(/VERSION="[^"]*"/, "VERSION=\"#{version}\"") if version
    result.gsub!(/OS="[^"]*"/, "OS=\"#{os}\"") if os
    result.gsub!(/ARCH="[^"]*"/, "ARCH=\"#{arch}\"") if arch
    result.gsub!(/DIRECTORY="[^"]*"/, "DIRECTORY=\"#{directory}\"") if directory
    result.gsub!(/FORCE="[^"]*"/, "FORCE=\"#{force}\"") if force
    result
  end
end

get "/" do
  content_type "text/plain"
  handle_install(INSTALL_SCRIPT, params["version"], params["directory"], params["os"], params["arch"], params["force"])
end

get "/robots.txt" do
  content_type "text/plain"
  ROBOTS
end

get "/VERSION" do
  content_type "text/plain"
  VERSION
end

get "/install.sh" do
  content_type "text/plain"
  handle_install(INSTALL_SCRIPT, params["version"], params["directory"], params["os"], params["arch"], params["force"])
end

# for historical purposes
get "/installer.sh" do
  content_type "text/plain"
  handle_install(INSTALL_SCRIPT, params["version"], params["directory"], params["os"], params["arch"], params["force"])
end

# for ops
get "/ops" do
  content_type "text/plain"
  handle_install(OPS_INSTALL_SCRIPT, params["version"], params["directory"], params["os"], params["arch"], params["force"])
end

get "/ops/" do
  content_type "text/plain"
  handle_install(OPS_INSTALL_SCRIPT, params["version"], params["directory"], params["os"], params["arch"], params["force"])
end

get "/ops/install.sh" do
  content_type "text/plain"
  handle_install(OPS_INSTALL_SCRIPT, params["version"], params["directory"], params["os"], params["arch"], params["force"])
end

get "/ops/VERSION" do
  content_type "text/plain"
  OPS_VERSION
end

# for armor
get "/armor" do
  content_type "text/plain"
  handle_install(ARMOR_INSTALL_SCRIPT, params["version"], params["directory"], params["os"], params["arch"], params["force"])
end

get "/armor/" do
  content_type "text/plain"
  handle_install(ARMOR_INSTALL_SCRIPT, params["version"], params["directory"], params["os"], params["arch"], params["force"])
end

get "/armor/install.sh" do
  content_type "text/plain"
  handle_install(ARMOR_INSTALL_SCRIPT, params["version"], params["directory"], params["os"], params["arch"], params["force"])
end

get "/armor/VERSION" do
  content_type "text/plain"
  ARMOR_VERSION
end

# Ext Vault routes
get "/ext/vault" do
  content_type "text/plain"
  handle_install(EXT_VAULT_INSTALL_SCRIPT, params["version"], params["directory"])
end

get "/ext/vault/install.sh" do
  content_type "text/plain"
  handle_install(EXT_VAULT_INSTALL_SCRIPT, params["version"], params["directory"])
end

get "/ext/vault/VERSION" do
  content_type "text/plain"
  EXT_VAULT_VERSION
end

get "/stats/curl" do
  content_type "application/json"
  handle_stats([
    "@dotenvx/dotenvx-darwin-amd64",
    "@dotenvx/dotenvx-darwin-arm64",
    "@dotenvx/dotenvx-darwin-x86_64",
    "@dotenvx/dotenvx-linux-aarch64",
    "@dotenvx/dotenvx-linux-amd64",
    "@dotenvx/dotenvx-linux-arm64",
    "@dotenvx/dotenvx-linux-x86_64",
    "@dotenvx/dotenvx-windows-amd64",
    "@dotenvx/dotenvx-windows-x86_64"
  ])
end

get "/stats/curl/darwin" do
  content_type "application/json"
  handle_stats([
    "@dotenvx/dotenvx-darwin-amd64",
    "@dotenvx/dotenvx-darwin-arm64",
    "@dotenvx/dotenvx-darwin-x86_64"
  ])
end

get "/stats/curl/linux" do
  content_type "application/json"
  handle_stats([
    "@dotenvx/dotenvx-linux-aarch64",
    "@dotenvx/dotenvx-linux-amd64",
    "@dotenvx/dotenvx-linux-arm64",
    "@dotenvx/dotenvx-linux-x86_64"
  ])
end

get "/stats/curl/windows" do
  content_type "application/json"
  handle_stats([
    "@dotenvx/dotenvx-windows-amd64",
    "@dotenvx/dotenvx-windows-x86_64"
  ])
end

get "/darwin/*" do
  arch = params["splat"].first
  handle_download("darwin", arch, params["version"])
end

get "/linux/*" do
  arch = params["splat"].first
  handle_download("linux", arch, params["version"])
end

get "/windows/*" do
  arch = params["splat"].first
  handle_download("windows", arch, params["version"])
end
