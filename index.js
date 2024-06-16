const express = require('express')
const axios = require('axios')
const path = require('path')
const tar = require('tar')
const tmp = require('tmp')
const fs = require('fs')
const { execSync } = require('child_process')
const app = express()

const PORT = process.env.PORT || 3000
const GITHUB_TOKEN = process.env.GITHUB_TOKEN

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

app.get('/', (req, res) => {
  res.type('text/plain')
  res.send(installerScript)
})

app.get('/VERSION', (req, res) => {
  res.type('text/plain')
  res.send(VERSION)
})

app.get('/installer.sh', (req, res) => {
  const scriptPath = path.join(__dirname, 'installer.sh')

  fs.readFile(scriptPath, 'utf8', (err, data) => {
    if (err) {
      res.status(500).send('Error reading the file')
      return
    }
    res.type('text/plain')
    res.send(data)
  })
})

app.get('/install.sh', (req, res) => {
  // /install.sh?version=X.X.X&directory=.
  const version = req.query.version
  const directory = req.query.directory

  // install.sh
  const scriptPath = path.join(__dirname, 'install.sh')

  fs.readFile(scriptPath, 'utf8', (err, data) => {
    if (err) {
      res.status(500).send('Error reading the file')
      return
    }

    // curl -sfS https://dotenvx.sh/install.sh?version=1.0.0
    if (version) {
      data = data.replace(/VERSION="[^"]*"/, `VERSION="${version}"`)
    }

    // curl -sfS https://dotenvx.sh/install.sh?directory=.
    if (directory) {
      data = data.replace(/DIRECTORY="[^"]*"/, `DIRECTORY="${directory}"`)
    }

    res.type('text/plain')
    res.send(data)
  })
})

app.get('/v2/:os/:arch(*)', async (req, res) => {
  const os = req.params.os.toLowerCase()
  let arch = req.params.arch.toLowerCase()
  let version = req.query.version

  // remove any extension from the arch parameter
  arch = arch.replace(/\.[^/.]+$/, '')

  // check if version is provided
  if (version) {
    if (version.startsWith('v')) {
      version = version.replace(/^v/, '')
    }
  } else {
    version = VERSION
  }

  const repo = `dotenvx-${os}-${arch}`
  const filename = `${repo}-${version}.tgz`
  const registryUrl = `https://registry.npmjs.org/@dotenvx/${repo}/-/${filename}`

  try {
    const response = await axios.get(registryUrl, { responseType: 'stream' })
    const tmpDir = tmp.dirSync({ unsafeCleanup: true }).name
    const tmpTarPath = path.join(tmpDir, filename)

    // extract the downloaded tarball to the temporary directory
    response.data.pipe(tar.x({
      cwd: tmpDir,
      strip: 1, // Strip the 'package' folder
      filter: path => path.startsWith('package/dotenvx') // Only extract files within the 'package' folder
    })).on('finish', () => {
      // permissions
      const dotenvxBinaryPath = path.join(tmpDir, 'dotenvx')
      fs.chmodSync(dotenvxBinaryPath, 0o755)

      // new tarball
      execSync(`tar -czf ${tmpTarPath} -C ${tmpDir} .`)

      // size of tarball
      const stat = fs.statSync(tmpTarPath)
      const tarballSize = stat.size

      // set the response headers
      res.setHeader('Content-Type', 'application/gzip')
      res.setHeader('Content-Length', tarballSize)

      // stream the tarball file to the response
      const readStream = fs.createReadStream(tmpTarPath)
      readStream.pipe(res).on('finish', () => {
        // Cleanup the temporary directory
        tmp.setGracefulCleanup()
      })
    }).on('error', error => {
      res.status(500).send('Error occurred while extracting the file: ' + error.message)
    })
  } catch (error) {
    res.status(500).send('Error occurred while fetching the file: ' + error.message)
  }
})

app.get('/:os/:arch', async (req, res) => {
  const os = req.params.os.toLowerCase()
  let arch = req.params.arch.toLowerCase()
  let version = req.query.version

  // Check if version is provided and prepend 'v' if necessary
  if (version) {
    if (!version.startsWith('v')) {
      version = 'v' + version
    }
  } else {
    version = 'latest'
  }

  // Convert .tgz to .tar.gz
  if (arch.endsWith('.tgz')) {
    arch = arch.replace('.tgz', '.tar.gz')
  }

  // Default to .tar.gz if no extension is provided
  if (!arch.includes('.')) {
    arch += '.tar.gz'
  }

  let filename = `dotenvx-${os}-${arch}`
  if (version !== 'latest') {
    filename = `dotenvx-${version.replace('v', '')}-${os}-${arch}`
  }

  // Constructing the URL to which we will proxy
  let proxyUrl
  if (version === 'latest') {
    // dotenvx.com/releases URL for the latest version (https://github.com/dotenvx/releases)
    proxyUrl = `https://dotenvx.com/releases/${version}/${filename}`
  } else {
    // GitHub releases URL for specific versions
    // https://github.com/dotenvx/dotenvx/releases/download/v0.6.9/dotenvx-0.6.9-darwin-amd64.tar.gz
    proxyUrl = `https://github.com/dotenvx/dotenvx/releases/download/${version}/${filename}`
  }

  try {
    const config = {
      responseType: 'stream'
    }

    // If the URL is a GitHub URL, add the Authorization header - 5,000 requests per hour
    if (proxyUrl.includes('github.com')) {
      config.headers = {
        Authorization: `token ${GITHUB_TOKEN}`
      }
    }

    // Using axios to get a response stream
    const response = await axios.get(proxyUrl, config)

    // Setting headers for the response
    res.setHeader('Content-Type', response.headers['content-type'])
    res.setHeader('Content-Length', response.headers['content-length'])

    // Piping the response stream to the client
    response.data.pipe(res)
  } catch (error) {
    res.status(500).send('Error occurred while fetching the file: ' + error.message)
  }
})

app.listen(PORT, () => {
  console.log(`Server is running on http://:${PORT}`)
})
