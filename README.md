# Run locally

`docker run --rm -it -p 4000:4000 --volume="$(pwd):/src/site" $(docker build -q .)`
note: it may take time to build the image and there will be no output until that happens.
