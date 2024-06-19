![curl -sfS https://dotenvx.sh/ | sh](https://dotenvx.com/binary-banner.png)
```sh
curl -sfS https://dotenvx.sh | sh
```
> [`dotenvx`](https://github.com/dotenvx/dotenvx#readme) binary installer
>
> * [see usage](https://github.com/dotenvx/dotenvx#readme)

&nbsp;

## Install

```sh
curl -sfS https://dotenvx.sh | sh
```

or self-execute this file:

```sh
curl -sfS https://dotenvx.sh > install.sh
chmod +x install.sh
./install.sh
```

more install examples:

```sh
# curl examples
curl -sfS "https://dotenvx.sh/" | sudo sh
curl -sfS "https://dotenvx.sh/?version=0.44.0" | sh
curl -sfS "https://dotenvx.sh/?directory=." | sh
curl -sfS "https://dotenvx.sh/?directory=/custom/path&version=0.44.0" | sh

# self-executing examples
./install.sh --version=0.44.0
./install.sh --directory=.
./install.sh --directory=/custom/path --version=0.44.0
./install.sh --help
```

## Usage

```sh
$ echo "HELLO=World" > .env
$ echo "console.log('Hello ' + process.env.HELLO)" > index.js

$ node index.js
Hello undefined # without dotenvx

$ dotenvx run -- node index.js
Hello World # with dotenvx
```

see [`dotenvx`](https://github.com/dotenvx/dotenvx) for extended usage guides.

---

#### more information

* alternatively, install with wget `wget -qO- https://dotenvx.sh/install.sh | sh`
* make sure you are using `https`, not `http`. We do not redirect for trust reasons.
* currently [dotenvx.sh](https://dotenvx.sh) is hosted at Heroku
