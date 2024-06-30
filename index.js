const express = require('express')
const path = require('path')
const tmp = require('tmp')
const fs = require('fs')
const { execSync } = require('child_process')
const app = express()

const PORT = process.env.PORT || 3000

const installScriptPath = path.join(__dirname, 'install.sh')
let installScript = ''
fs.readFile(installScriptPath, 'utf8', (err, data) => {
  if (err) {
    console.error('Error reading install.sh script', err)
    process.exit(1) // Exit if the script cannot be read
  }
  installScript = data
})

// Read the version file once at the start
let VERSION = '1.4.0' // hardcode for added redundancy (in case read fails somehow)
fs.readFile(path.join(__dirname, 'VERSION'), 'utf8', (err, data) => {
  if (err) {
    console.error('Error reading VERSION file', err)
    process.exit(1) // Exit if the script cannot be read
  }
  VERSION = data.trim()
})

// Read the robots.txt once at the start
let ROBOTS = '' // hardcode for added redundancy (in case read fails somehow)
fs.readFile(path.join(__dirname, 'robots.txt'), 'utf8', (err, data) => {
  if (err) {
    console.error('Error reading robots.txt file', err)
    process.exit(1) // Exit if the script cannot be read
  }
  ROBOTS = data.trim()
})

// dotenvx-ext-hub
const extHubInstallScriptPath = path.join(__dirname, 'ext/hub/install.sh')
let extHubInstallScript = ''
fs.readFile(extHubInstallScriptPath, 'utf8', (err, data) => {
  if (err) {
    console.error('Error reading ext/hub/install.sh script', err)
  }
  extHubInstallScript = data
})

const handleDownload = async (req, res, os, name) => {
  let arch = req.params.arch.toLowerCase().trim()
  let version = req.query.version

  // Remove any extension from the arch parameter
  arch = arch.replace(/\.[^/.]+$/, '')

  // Check if version is provided
  if (version) {
    if (version.startsWith('v')) {
      version = version.replace(/^v/, '')
    }
  } else {
    version = VERSION
  }

  let binaryName = name
  // Modify binaryName if windows
  if (os === 'windows') {
    binaryName = `${binaryName}.exe`
  }

  const repo = `${name}-${os}-${arch}`
  const filename = `${repo}-${version}.tgz`
  const registryUrl = `https://registry.npmjs.org/@dotenvx/${repo}/-/${filename}`

  try {
    const tmpDir = tmp.dirSync().name // Create unique tmp directory
    const tmpDownloadPath = path.join(tmpDir, filename) // Path for the downloaded file from npm
    const tmpTarPath = path.join(tmpDir, 'output.tgz') // Path for the new tarball

    // Download, un-tar, grab binary, and re-tar
    const command = `
      curl -sS -L ${registryUrl} -o ${tmpDownloadPath} &&
      tar -xzf ${tmpDownloadPath} -C ${tmpDir} --strip-components=1 package &&
      chmod 755 ${path.join(tmpDir, binaryName)} &&
      tar -czf ${tmpTarPath} -C ${tmpDir} ${binaryName}
    `
    execSync(command)

    // Stat
    const stat = fs.statSync(tmpTarPath)

    // Set headers
    res.setHeader('Content-Type', 'application/gzip')
    res.setHeader('Content-Length', stat.size)
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`)

    // Stream tarball to the response
    const readStream = fs.createReadStream(tmpTarPath)
    readStream.pipe(res)
  } catch (error) {
    console.log('error', error.message)
    res.status(500).send('500 error')
  }
}

const formatNumber = function (num) {
  if (num >= 1000000) {
    return (num / 1000000).toFixed(1) + 'M'
  } else if (num >= 1000) {
    return (num / 1000).toFixed(1) + 'k'
  } else {
    return num.toString()
  }
}

const handleStats = async (req, res, packages) => {
  try {
    const downloadCounts = await Promise.all(
      packages.map(async (pkg) => {
        const response = await fetch(`https://api.npmjs.org/downloads/point/last-year/${pkg}`)
        const data = await response.json()
        return data.downloads
      })
    )

    const totalDownloads = downloadCounts.reduce((acc, count) => acc + count, 0)
    const formattedCount = formatNumber(totalDownloads)

    res.json({
      schemaVersion: 1,
      label: 'downloads',
      message: formattedCount,
      color: 'brightgreen'
    })
  } catch (error) {
    console.error(error)
    res.status(500).send('Error fetching download counts')
  }
}

const handleInstall = async (req, res, installScript) => {
  // /install.sh?version=X.X.X&directory=.
  const version = req.query.version
  const directory = req.query.directory

  let result = installScript // necessary so that the global installScript is not modified by a single user and affects all other users

  // curl -sfS https://dotenvx.sh/install.sh?version=1.0.0
  if (version) {
    result = result.replace(/VERSION="[^"]*"/, `VERSION="${version}"`)
  }

  // curl -sfS https://dotenvx.sh/install.sh?directory=.
  if (directory) {
    result = result.replace(/DIRECTORY="[^"]*"/, `DIRECTORY="${directory}"`)
  }

  res.type('text/plain')
  res.send(result)
}

app.get('/', (req, res) => {
  handleInstall(req, res, installScript)
})

app.get('/robots.txt', (req, res) => {
  res.type('text/plain')
  res.send(ROBOTS)
})

app.get('/VERSION', (req, res) => {
  res.type('text/plain')
  res.send(VERSION)
})

app.get('/install.sh', (req, res) => {
  handleInstall(req, res, installScript)
})

// for historical purposes
app.get('/installer.sh', (req, res) => {
  handleInstall(req, res, installScript)
})

// for ext/hub
app.get('/ext/hub', (req, res) => {
  handleInstall(req, res, extHubInstallScript)
})
app.get('/ext/hub/install.sh', (req, res) => {
  handleInstall(req, res, extHubInstallScript)
})

app.get('/stats/curl', async (req, res) => {
  const packages = [
    '@dotenvx/dotenvx-darwin-amd64',
    '@dotenvx/dotenvx-darwin-arm64',
    '@dotenvx/dotenvx-darwin-x86_64',
    '@dotenvx/dotenvx-linux-aarch64',
    '@dotenvx/dotenvx-linux-amd64',
    '@dotenvx/dotenvx-linux-arm64',
    '@dotenvx/dotenvx-linux-x86_64',
    '@dotenvx/dotenvx-windows-amd64',
    '@dotenvx/dotenvx-windows-x86_64'
  ]

  handleStats(req, res, packages)
})

app.get('/stats/curl/darwin', async (req, res) => {
  const packages = [
    '@dotenvx/dotenvx-darwin-amd64',
    '@dotenvx/dotenvx-darwin-arm64',
    '@dotenvx/dotenvx-darwin-x86_64'
  ]

  await handleStats(req, res, packages)
})

app.get('/stats/curl/linux', async (req, res) => {
  const packages = [
    '@dotenvx/dotenvx-linux-aarch64',
    '@dotenvx/dotenvx-linux-amd64',
    '@dotenvx/dotenvx-linux-arm64',
    '@dotenvx/dotenvx-linux-x86_64'
  ]

  await handleStats(req, res, packages)
})

app.get('/stats/curl/windows', async (req, res) => {
  const packages = [
    '@dotenvx/dotenvx-windows-amd64',
    '@dotenvx/dotenvx-windows-x86_64'
  ]

  await handleStats(req, res, packages)
})

app.get('/darwin/:arch(*)', async (req, res) => {
  await handleDownload(req, res, 'darwin', 'dotenvx')
})

app.get('/linux/:arch(*)', async (req, res) => {
  await handleDownload(req, res, 'linux', 'dotenvx')
})

app.get('/windows/:arch(*)', async (req, res) => {
  await handleDownload(req, res, 'windows', 'dotenvx')
})

app.listen(PORT, () => {
  console.log(`Server is running on http://:${PORT}`)
})
