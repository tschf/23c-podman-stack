# README

Set up instructions:

Grab the images if you don't already have them. I like to do this is an independent
step rather than letting the container engine pull them in a "run" operation.

```sh
./images.sh
```

Provision all the pieces - this script does the following tasks:

* Makes a folder in your HOME - $HOME/db-free
* Creates 2 secrets - 1 for sys and 1 for a app dev user which I've called "devver".

```sh
./tearup.sh
```

