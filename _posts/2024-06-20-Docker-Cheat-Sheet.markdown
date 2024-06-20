---
layout: typed_post
title:  Docker Cheat Sheet
date:   2024-06-20 12:11:00 +1000
categories: technology
tags: explainer
summary: "\"I am tormented with an everlasting itch for things remote\" - Herman Melville, Moby-Dick or, The Whale"
thumbnail: "<ul><li>Container - a runnable unit of software that contains code and dependencies. It can be easily run on a docker host</li><li>Docker host - the machine (can be a VM) that runs the shared OS kernel, docker and containers...</li></ul>"
preview: /assets/img/previews/docker.jpeg

---

## Definitions

[https://github.com/erikw/jekyll-glossary_tooltip](https://github.com/erikw/jekyll-glossary_tooltip)

- Container - a runnable unit of software that contains code and dependencies. It can be easily run on a docker host
- Docker host - the machine (can be a VM) that runs the shared OS kernel, docker and containers
- Image - read-only template with instructions for creating a Docker container, the image name can contain an optional repository name `<repo>/<name>`
- Tag - optional identifier of an image (in addition to the image name) typically a specific version or variant of an image. e.g. `latest`
- Mount - attach a volume to a location in a container, there are two types volume mount mounts a volume under `var/lib/docker/volumes/` bind mounts mount any directory on the host
- Layers - each line in the `Dockerfile` creates a layer in the image, each layer only stores the changes from the previous layer. This allows for caching and reuse of layers which is faster and space efficient. Image l ayers are readonly and can only be modified by creating a new build.
- Volume - allows data to be persisted on the host so when a container is destroyed the data on the volume is not lost
- Registry - a server for storing and distributing docker images, e.g. docker.io
- Namespace - linux resources are namespaced to a container to isolate them
- Docker Daemon - `dockerd` is the persistent process that manages containers
- Docker Engine - the docker daemon, API and CLI
- Storage driver - depends on the underlying OS
- Bridge - the default network a container gets attached to
- Node - physical or virtual machines running Docker Engine, part of a docker swarm. There are two types of nodes - managers and workers. List with`docker node ls`
- Service - One or more containers deployed on a docker host or across a swarm `docker service create -replicas=3 <image name>`
- Stacks - A group of interrelated services, configured in a `docker-compose.yml` (version 3) file. Includes config such as number of instances, placement preferences, resource constraints
- Registry - repository for images e.g dockerhub, can also create a private registry - see the `registry` image on dockerhub for running a registry container

## Commands

Note: when using `container id` you only need to use the first few characters such that the id is distinct to other container ids on the system.

- `docker run <image name>[:<tag>] <command to run in container>`   - run a local image or pull and run an image on docker hub
  - `-it` log in to container to interact with it (i: listen to inputs, t: provide terminal)
  - `-d` detached, run docker container in background mode
  - `-p <host port>:<container port>` - map the host’s port to the container port (port mapping)
  - `-v <host dir>:<container dir>` - map (mount) the container directory to the host so data is persisted if the container is destroyed
  - `-u <user>` the user on the host the container runs as???
  - `-e <VAR>=<value>` set environment variables
  - `--entrypoint <new entrypoint>` override the entrypoint
  - `--link <name of linked container on host>:<hostname of the linked container used inside this container>` creates an entry in this container’s hosts file with the IP of the linked container with the hostname given `deprecated`
  - `-H=<ip address>` run on a docker engine on a remote host
  - `--cpus=<decimal value>` limits the percentage cpu the container can consume
  - `--memory=<string>` limits the amount of memory the container can consume
  - `-v <volume name>:<path inside container>` mount the given volume and attach the container path to it (if the volume does not exist docker will create it) `deprecated` `--mount` is preferred
  - `--mount type=<bind or volume>,source=<location on host>,target=<location on container>` create a bind mount or volume mount ???
  - `--network=<network name>` specify the network the container is attached to (none, host, user defined)
- `docker exec <container name> <command>` - run a command in the given container
- `docker attach <container id>` - attach a container to the terminal to view output
- `docker ps` - list containers
  - `-a` all containers - includes exited containers
- `docker stop <container name or id>` - stop a container (container still exists in an exited state)
  - get name/id from `docker ps`
- `docker rm <container name or id>` - deletes a container, prints container name if successful
- `docker images` - lists local images
- `docker rmi <image name>` remove a local image (if containers are using this image the command will fail)
- `docker pull <image name>` download the image without running it
- `docker inspect <container name or id>` - lists the details of the container including mounts, network settings, environment variables, etc.
- `docker logs <container name or id>` view the containers logs
- `docker build <loation of Dockerfile>` - create an image using a dockerfile on your local system
  - `-t <something>` renames or tags the image
- `docker push <image name>` publish your image on the docker registry
- `docker history <image name>` lists the layers of an image
- `docker login <optional registry`> log in to dockerhub or the named registry to allow images to be pushed and in the case of private registries, pulled
- `docker-compose up`  use a yaml config file to run a stack of containers on a single docker host
- `docker volume create <volume name>` creates a directory on the host where data will be persisted (under `var/lib/docker/volumes/<volume name>`)
- `docker history <image id>` lists the steps that created the image
- `docker network create <network name>` create a user defined network
- `docker network ls` list the networks

## Dockerfile

Instructions to create the image contains instructions (caps) and arguments

```docker
FROM Ubuntu

RUN apt-get update
RUN apt-get install python

RUN pip install flask
RUN pip install flask-mysql

COPY . /opt/source-code

ENTRYPOINT FLASK_APP=/opt/source-code/app.py flask run
```

### Dockerfile CMD vs ENTRYPOINT

params at the end of `docker run` will be appended to `ENTRYPOINT`.

If using `CMD` params will overwrite `CMD` entirely.

Use both to provide a default value

```docker
# docker run ubuntu-sleeper 
# override CMD: docker run ubuntu-sleeper **sleep 10**
FROM Ubuntu

CMD sleep 5
```

```docker
# pass params to ENTRYPOINT: docker run ubuntu-sleeper **10**
# this will fail if the param not provided
FROM Ubuntu

ENTRYPOINT sleep
```

```docker
# use default value: docker run ubuntu-sleeper
# override default value: docker run ubuntu-sleeper **10**
FROM Ubuntu

ENTRYPOINT ["sleep"]

CMD ["5"]
```

## Docker compose

Use a docker compose file `docker-compose up` instead of a set of manual `docker run` commands

```yaml
# docker-compose.yml (version 1 example)

redis:
	image: redis

db:
	image: postgres:9.4

vote:
	build: ./vote
	ports:
		- 5000:80
	links:
		- redis
```

```yaml
# docker-compose.yml (version 2 example)

version: 2

services:
	redis:
		image: redis
		networks:
			- back-end
		
	db:
		image: postgres:9.4
		networks:
			- back-end
		
	vote:
		image: voting-app
		ports:
			- 5000:80
		depends_on:
			- redis
		networks:
			- front-end
			- back-end
	
networks:
	front-end:
	back-end:
```

## Orchestration

Tools and scripts to monitor the state, performance and health and take necessary actions to remediate issues.

- docker swarm - easy to set up, lacks advanced tools, possible deprecation risk?
- kubernetes - harder to set up, provides advanced features such as autoscaling, rolling updates, 3rd party plugins

## Gotchas

- containers exit when their command exits
- by default containers run in non interactive mode and do not listen to inputs
- when containers are removed their data is also removed unless the files are persisted on the host
- `latest` is the default tag if none is specified
- by default containers are created and run as a root user, unless you or the base image specify a different user - this can be done in the Dockerfile or with the `--user` option in `docker run` . Be carful though, some container images expect to run as root
- configuring the correct users and permissions between containers and hosts is [complicated](https://jtreminio.com/blog/running-docker-containers-as-current-host-user/)
- layers are cached if them or the layers below them are unchanged
- the format of `docker-compose.yml` has evolved over time and can vary according to the version used
- `docker-compose` is a separate install to docker engine
- image defaults, using `nginx` is assuming the following `docker.io/nginx/nginx`
- by default there are no restrictions on the resources (CPU/Memory) a container can consume
- data is stored on the host under `/var/lib/docker` by default
- there are two types of mounts - volume mounts on docker volumes and bind mounts on directories on the host
- all containers are attached to the Bridge network by default
- docker has a built in DNS server that allows containers to resolve other container names to IPs (DNS runs at `127.0.0.11`)
- Docker desktop on Mac creates a linux VM on HyperKit to provide the linux kernel to containers
- The usage of the word tag can be confusing. A tag follows the image name in identifying the image `<image name>:<tag>` but [commands](https://docs.docker.com/reference/cli/docker/image/tag/) that tag images can actually change the image name and repository as well.

## References

[https://github.com/dockersamples/example-voting-app](https://github.com/dockersamples/example-voting-app)

[Home](https://docs.docker.com/)

[Play with Docker](https://www.docker.com/play-with-docker/)

[Play with Kubernetes](https://labs.play-with-k8s.com/)

