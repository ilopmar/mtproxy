# MTProxy

This repository contains the source for a Docker image for Telegram MTProxy, based on Photon OS 5.0. The official [Telegram MTProxy repository](https://github.com/TelegramMessenger/MTProxy) hasn't been updated or maintained in over five years.
The `Dockerfile` is inspired by this [guide](https://gist.github.com/rameerez/8debfc790e965009ca2949c3b4580b91).

## Running MTProxy

To run `MTProxy`, you need a secret key. Generate one using:

```shell
$ head -c 16 /dev/urandom | xxd -ps
```

Then, start the container:

```shell
$ docker run -it --rm -p 8443:8443 -p 8888:8888 -e SECRET_KEY=__YOUR_SECRET_KEY__ ilopmar/mtproxy:latest
```

The entrypoint script will attempt to determine your internal and external IP addresses. To override these, set the `PRIVATE_IP` and `PUBLIC_IP` environment variables:

```shell
$ docker run -it --rm -p 8443:8443 -p 8888:8888 -e SECRET_KEY=__YOUR_SECRET_KEY__ -e PRIVATE_IP=10.1.2.3 -e PUBLIC_IP=123.123.123.123 ilopmar/mtproxy:latest
```

When `MTProxy` starts, it displays the private and public IP addresses and the URL to use in the Telegram application to connect to the proxy:

```shell
============ MTProxy ============
Using PRIVATE_IP: 10.1.2.3
Using PUBLIC_IP: 123.123.123.123

 Use the following proxy in Telegram: 
  tg://proxy?server=123.123.123.123&port=8443&secret=__YOUR_SECRET_KEY__
============ MTProxy ============
```

The container listens on port `8443` for client connections and on port `8888` for internal statistics. To change the ports, modify the `Dockerfile` and build your own image (see [Build the Docker Image](#build-the-docker-image)).

## Docker Compose

To run `MTProxy` with Docker Compose:

```yaml
services:
  mtproxy:
    container_name: mtproxy
    image: ilopmar/mtproxy:latest
    restart: unless-stopped
    env_file:
      - .env
    ports:
      - 8443:8443
```

Create a `.env` file with your secret key:

```
SECRET_KEY=__YOUR_SECRET_KEY__
```

Then, execute:

```shell
$ docker-compose up -d
```

## Build the Docker Image

To build your own modified version, clone the repository and run:

```shell
$ docker build -t mtproxy .
```

## AMD & ARM Architectures

`MTProxy` doesn't compile on ARM architectures, but you can compile it on an AMD64 machine and run it on an ARM instance like Oracle Cloud Ampere.

After creating the Docker image and pushing it to a registry, set up your ARM instance with QEMU (assuming you're using Ubuntu or Debian):

```shell
$ sudo apt-get update
$ sudo apt-get install qemu qemu-user-static binfmt-support

# If the previous don't work, try with
$ sudo apt-get install qemu-system qemu-utils qemu-user qemu-user-static binfmt-support
```

To configure multi-architecture container support, run:

```shell
$ docker run --rm --privileged tonistiigi/binfmt --install all
```

Now you can run `MTProxy` on ARM, although you might see a warning:

```shell
WARNING: The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested
```

To remove the warning and run `MTProxy` as expected, use the flag `--platform linux/amd64`:

```shell
$ docker run -it --rm -p 8443:8443 -p 8888:8888 --platform linux/amd64 -e SECRET_KEY=__YOUR_SECRET_KEY__ ilopmar/mtproxy:latest
```

Enjoy your Telegram proxy! :)
