const express = require('express')
const axios = require('axios')
const path = require('path')
const fs = require('fs')
const app = express()
const port = process.env.PORT || 3000

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
  const userAgent = req.headers['user-agent']
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

  // Constructing the URL to which we will proxy
  const proxyUrl = `https://dotenvx.com/releases/${version}/dotenvx-${os}-${arch}`

  try {
    // Using axios to get a response stream
    const response = await axios.get(proxyUrl, {
      responseType: 'stream'
    })

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
  // Construct the URL to proxy the request to /releases/VERSION
  const proxyUrl = 'https://dotenvx.com/releases/VERSION'

  try {
    // Using axios to get a response stream
    const response = await axios.get(proxyUrl, {
      responseType: 'stream'
    })

    // Setting headers for the response
    res.setHeader('Content-Type', response.headers['content-type'])
    res.setHeader('Content-Length', response.headers['content-length'])

    // Piping the response stream to the client
    response.data.pipe(res)
  } catch (error) {
    res.status(500).send('Error occurred while fetching the file: ' + error.message)
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

app.listen(port, () => {
  console.log(`Server is running on http://:${port}`)
})
