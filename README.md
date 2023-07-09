# README

[23c Docs Home](https://docs.oracle.com/en/database/oracle/oracle-database/23/index.html)

## Pre-requisites

This assumes you're on linux - some of the scripts might not work for you.

* Uses curl
* Uses pwgen

## Setup

Grab the images if you don't already have them. I like to do this is an independent
step rather than letting the container engine pull them in a "run" operation.

```sh
./images.sh
```

To get everything set up, there is a `./tearup.sh` script which sets everything
up. It does the following actions:

Provisions a pod with 2 containers:

* db
* ords

2 Volumes are created to store Oracle data and ORDS config redpectively:

* oradata
* ordsconfig

Configures the following in the database:

* New schema `DEVVER`
* New APEX workspace, `APP_DEV`
* Rest enables the `DEVVER` schema
  
In the future if you want to spin up or down the containers just run:

```sh
podman pod stop dbfree-pod 
podman pod start dbfree-pod 
```
