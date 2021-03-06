# swm

The missing tooling for a great Docker swarm experience

## Introduction

Docker swarm mode is a container orchestration system with just the right level of abstraction for small to medium sized infrastructures. In contrast to alternatives like Kubernetes, it has a relatively low level of complexity while being quite developer-friendly. 

That said, the current interface is lacking especially in terms of managing cluster nodes and applications. `swm` aims to be the missing piece for managing services and containers using *infrastructure as code* with a minimum amount of boilerplate. 

In practice, `swm` can be used as a commandline extension to the main `docker` CLI command.


## Installation

You can either download a prebuilt binary (Linux only) or build it yourself (Linux / Mac). (See below for build instructions.)

The latest version can be downloaded from the [releases](https://github.com/djmaze/swm/releases) page.


#### Standalone

Copy the binary into a directory in your `PATH`. Then just run `swm` in order to use it.

#### Docker commandline extension

Alternatively, you can install it as a docker commandline extension:

```bash
mkdir -p ~/.docker/cli-plugins
cp swm ~/.docker/cli-plugins/docker-swm
```

Now, you can run it using `docker swm`

## Usage

Commands are grouped into three categories:

* cluster
* stack
* service

Try out `swm cluster`, `swm stack` or `swm service` in order to find the available commands.

## Development

### Build

You can build the binary locally or via Docker.

When using Docker, the binary will be statically linked. It can thus be used on any amd64-compatible Linux system.

#### Local

* Install [Crystal](https://crystal-lang.org) >= 0.33.0
* Clone this repository
* Build the binary:
    ```bash
    shards build
    ```
If the build was successful, you can find the final executable at `bin/swm`. 

#### With Docker

* Install Docker and `make`
* Clone this repository
* Build the binary:
    ```bash
    sudo -E make
    ```
If the build was successful, you can find the final executable at `bin/swm`. 

## TODO

- [ ] Add documentation
- [ ] Add spec suite
- [ ] Add command `service logs --latest <service name>`

## Contributing

1. Fork it (<https://github.com/your-github-user/swm/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Martin Honermeyer](https://github.com/your-github-user) - creator and maintainer
