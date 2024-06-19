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
    console.error('Error reading installer script', err)
    process.exit(1) // Exit if the script cannot be read
  }
  installScript = data
})

// Read the installer script once at the start
const installerScriptPath = path.join(__dirname, 'installer.sh')
let installerScript = ''
fs.readFile(installerScriptPath, 'utf8', (err, data) => {
  if (err) {
    console.error('Error reading installer script', err)
    process.exit(1) // Exit if the script cannot be read
  }
  installerScript = data
})

// Read the version file once at the start
let VERSION = '0.44.3' // hardcode for added redundancy (in case read fails somehow)
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

const handleDownload = async (req, res, os) => {
  let arch = req.params.arch.toLowerCase().trim()
  let version = req.query.version
  let binaryName = 'dotenvx'

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

  // Modify binaryName if windows
  if (os === 'windows') {
    binaryName = 'dotenvx.exe'
  }

  const repo = `dotenvx-${os}-${arch}`
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

app.get('/', (req, res) => {
  // /install.sh?version=X.X.X&directory=.
  const version = req.query.version
  const directory = req.query.directory

  let result = installScript // necessary so that the global installScript is not modified by a singe user and affects all other users

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
  // /install.sh?version=X.X.X&directory=.
  const version = req.query.version
  const directory = req.query.directory

  let result = installScript // necessary so that the global installScript is not modified by a singe user and affects all other users

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
})

// deprecated - to be replaced with install.sh
app.get('/installer.sh', (req, res) => {
  res.type('text/plain')
  res.send(installerScript)
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

  try {
    const downloadCounts = await Promise.all(
      packages.map(async (pkg) => {
        const response = await fetch(`https://api.npmjs.org/downloads/point/last-year/${pkg}`)
        const data = await response.json()
        return data.downloads
      })
    )

    const totalDownloads = downloadCounts.reduce((acc, count) => acc + count, 0)

    res.json({
      schemaVersion: 1,
      label: 'downloads',
      message: totalDownloads.toString(),
      color: 'brightgreen'
    })
  } catch (error) {
    console.error(error)
    res.status(500).send('Error fetching download counts')
  }
})

app.get('/darwin/:arch(*)', async (req, res) => {
  await handleDownload(req, res, 'darwin')
})

app.get('/linux/:arch(*)', async (req, res) => {
  await handleDownload(req, res, 'linux')
})

app.get('/windows/:arch(*)', async (req, res) => {
  await handleDownload(req, res, 'windows')
})

app.listen(PORT, () => {
  console.log(`Server is running on http://:${PORT}`)
})
