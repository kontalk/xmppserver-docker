Kontalk HTTP upload component image
===================================

This is a Docker image for the HTTP upload component of a Kontalk server.

To build this image just run this from a terminal:

```shell
docker build -t kontalk/httpupload .
```

The following environment variables are mandatory:

* `HTTPUPLOAD_MAX_SIZE`: max upload file size in bytes
* `HTTPUPLOAD_LISTEN_PORT`: service port exposed to host
* `HTTPUPLOAD_PUT_URL`: upload URL for clients (must be a public URL)
* `HTTPUPLOAD_GET_URL`: download URL for clients (must be a public URL)
