Kontalk server for Docker
=========================

Here you may find a few scripts and files to build a Kontalk container
(actually 3 containers) for hosting a Kontalk server.

Before running the actual build, you need to check and configure a few things.

## Requirements

* A recent Linux distro (we suggest Debian)
* Docker
* Docker Compose

## Configure the containers

Copy `database.properties.dist` to `database.properties` and modify MySQL root
and kontalk password.

Copy  `tigase.properties.dist` to `tigase.properties` and modify the values
inside. More details about the meaning of the configuration can be found in
the [image README file](tigase/README.md).

At this point, if you want to just run a development server for tests, just
go straight below to [the actual build](#build-the-containers).

## Setup for a production enviroment

A production environment will require prior creation of a SSL certificate and
possibly a GPG key for the server. The latter will be created on demand on
first run if not found. For the scripts to use them, certificate and keys must
be located in:

* `data/server-private.key`: GPG server private key (**must not be password-protected!**)
* `data/server-public.key`: GPG server public key
* `data/privatekey.pem`: SSL private key
* `data/certificate.pem`: SSL certificate
* `data/cachain.pem`: SSL certificate authorities chain (optional)

Your setup will also surely include some tweaking on the server configuration.
Copy the default `data/init.properties.in.dist` to `data/init.properties.in`
and you can edit Tigase parameters any way you like.

> When configuring Tigase init.properties.in file, leave placeholders for
variables untouched (e.g. `{{ .Env.FINGERPRINT }}`): they will be replaced
automatically.

The local server tutorial can be used to configure some of the parameters,
e.g. [registration providers](/docs/local-server-howto.md#registration) or
[push notifications](/docs/local-server-howto.md#push-notifications).

## Build the containers

Run this command:

```
./build.sh [dev|prod]
```

Pass either `dev` or `prod` to begin a development build or a production build.

The script will build the images and prepare your environment for 3 containers:

* **tigase**: it will contain the actual Tigase server
* **db**: the MySQL database server
* **httpupload**: it will run the HTTP upload component needed to upload media (pictures, audio files, etc.)

## Run the containers

Run this command:

```
docker-compose up -d
```

All 3 containers will start. Remove the `-d` to run the containers in the foreground.
