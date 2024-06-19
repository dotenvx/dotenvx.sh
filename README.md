![curl -sfS https://dotenvx.sh/ | sh](https://dotenvx.com/binary-banner.png)
```sh
curl -sfS https://dotenvx.sh/install.sh | sh
```
> [`dotenvx`](https://github.com/dotenvx/dotenvx#readme) binary installer
>
> * [see usage](https://github.com/dotenvx/dotenvx#readme)

&nbsp;

./install.sh
___________________________________________________________________________________________________
|      _                                                                                          |
|     | |     | |                                                                                 |
|   __| | ___ | |_ ___ _ ____   ____  __                                                          |
|  / _` |/ _ \| __/ _ \ '_ \ \ / /\ \/ /                                                          |
| | (_| | (_) | ||  __/ | | \ V /  >  <                                                           |
|  \__,_|\___/ \__\___|_| |_|\_/  /_/\_\                                                          |
|                                                                                                 |
|                                                                                                 |
|  *a better dotenv*–from the creator of [`dotenv`](https://github.com/motdotla/dotenv).          |
|                                                                                                 |
|  * run anywhere (cross-platform)                                                                |
|  * multi-environment                                                                            |
|  * encrypted envs                                                                               |
|                                                                                                 |
|  ## Install                                                                                     |
|                                                                                                 |
|  ```sh                                                                                          |
|  curl -sfS https://dotenvx.sh/install.sh | sh                                                   |
|  ```                                                                                            |
|                                                                                                 |
|  or self-execute this file:                                                                     |
|                                                                                                 |
|  ```sh                                                                                          |
|  curl -sfS https://dotenvx.sh/install.sh > install.sh                                           |
|  chmod +x install.sh                                                                            |
|  ./install.sh                                                                                   |
|  ```                                                                                            |
|                                                                                                 |
|  more install examples:                                                                         |
|                                                                                                 |
|  ```sh                                                                                          |
|  # curl examples                                                                                |
|  curl -sfS "https://dotenvx.sh/install.sh" | sudo sh                                            |
|  curl -sfS "https://dotenvx.sh/install.sh?version=0.44.0" | sh                                  |
|  curl -sfS "https://dotenvx.sh/install.sh?directory=." | sh                                     |
|  curl -sfS "https://dotenvx.sh/install.sh?directory=/custom/path&version=0.44.0" | sh           |
|                                                                                                 |
|  # self-executing examples                                                                      |
|  ./install.sh --version=0.44.0                                                                  |
|  ./install.sh --directory=.                                                                     |
|  ./install.sh --directory=/custom/path --version=0.44.0                                         |
|  ./install.sh --help                                                                            |
|  ```                                                                                            |
|                                                                                                 |
|  ## Usage                                                                                       |
|                                                                                                 |
|  ```sh                                                                                          |
|  $ echo "HELLO=World" > .env                                                                    |
|  $ echo "console.log('Hello ' + process.env.HELLO)" > index.js                                  |
|                                                                                                 |
|  $ node index.js                                                                                |
|  Hello undefined # without dotenvx                                                              |
|                                                                                                 |
|  $ dotenvx run -- node index.js                                                                 |
|  Hello World # with dotenvx                                                                     |
|  ```                                                                                            |
|                                                                                                 |
|  see [`dotenvx`](https://github.com/dotenvx/dotenvx) for extended usage guides.                 |
|                                                                                                 |
|_________________________________________________________________________________________________|

#### more information

* alternatively, install with wget `wget -qO- https://dotenvx.sh/install.sh | sh`
* make sure you are using `https`, not `http`. We do not redirect for trust reasons.
* currently [dotenvx.sh](https://dotenvx.sh) is hosted at Heroku
