# Run locally

`docker run --rm -it -p 4000:4000 --volume="$(pwd):/src/site" $(docker build -q .)`
