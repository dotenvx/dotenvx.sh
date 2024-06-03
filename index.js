const express = require('express')
const axios = require('axios')
const path = require('path')
const fs = require('fs')
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

app.get('/', (req, res) => {
  // Check User-Agent to determine the response
  const userAgent = req.headers['user-agent'] || ''
  if (userAgent.includes('curl') || userAgent.includes('wget')) {
    res.type('text/plain')
    res.send(installerScript)
  } else {
    res.redirect('https://dotenvx.com')
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

app.get('/VERSION', async (req, res) => {
  const proxyUrl = 'https://dotenvx.com/releases/VERSION'

  try {
    // Using axios to get the response as text
    const response = await axios.get(proxyUrl, {
      responseType: 'text' // Fetch as plain text
    })

    res.type('text/plain')
    res.send(response.data)
  } catch (error) {
    res.status(500).send('Error occurred while fetching the data: ' + error.message)
  }
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
  const scriptPath = path.join(__dirname, 'install.sh')

  fs.readFile(scriptPath, 'utf8', (err, data) => {
    if (err) {
      res.status(500).send('Error reading the file')
      return
    }
    res.type('text/plain')
    res.send(data)
  })
})

app.listen(PORT, () => {
  console.log(`Server is running on http://:${PORT}`)
})
