Kontalk XMPP server image
=========================

This is a Docker environment for building a Docker image with a ready-to-use Kontalk server.

This image can easily be used with a Docker Compose script also found in this repository.  
As a matter of fact, this image can't work alone: it needs configuration files and a database container.  

To build this image just run this from a terminal:

```shell
./build.sh
```

You can optionally pass the git branch to use as an argument to the script:

* master (default)
* staging (mostly stable, used in main Kontalk server)
* production (stable)

When executed in a container, it will generate server keys automatically for testing purposes.
However, for production environments, it's highly recommended to keep keys exported somewhere else.

The following environment variables are mandatory:

* `XMPP_SERVICE`: XMPP service name (not necessarily the container hostname)
* `MYSQL_PASSWORD`: password of the MySQL kontalk account
* `MYSQL_ROOT_PASSWORD`: password for the MySQL root account
* `MYSQL_TIMEZONE`: MySQL timezone
* `HTTPUPLOAD_MAX_SIZE`: max upload file size in bytes

The following variables will be used if available:

* `CERT_LETSENCRYPT`: use Let's Encrypt service for generating server certificates (**not implemented yet**)
