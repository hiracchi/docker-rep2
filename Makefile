PACKAGE=registry.gitlab.com/hiracchi/docker-rep2
TAG=latest
CONTAINER_NAME=rep2

.PHONY: all build

all: build

build:
	docker build \
		-f Dockerfile \
		-t "${PACKAGE}:${TAG}" . 2>&1 | tee out.build

start:
	docker run -d \
		--rm \
		--name ${CONTAINER_NAME} \
		-p "8080:80" \
		--volume "${PWD}/ext:/ext" \
		"${PACKAGE}:${TAG}"
	@sleep 1
	docker ps -a



stop:
	docker rm -f ${CONTAINER_NAME}


restart: stop start


term:
	docker exec -it ${CONTAINER_NAME} /bin/bash


logs:
	docker logs ${CONTAINER_NAME}
