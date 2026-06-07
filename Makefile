ARCH ?= $(shell uname -m)

clingo-lua54:
	docker build -f Dockerfile.lua5x --build-arg LUA_VERSION=5.4 -t clingo-lua54 .

clingo-lua54-bookworm:
	docker build -f Dockerfile.lua5x --build-arg BASE_IMAGE=debian:bookworm --build-arg LUA_VERSION=5.4 -t clingo-lua54:bookworm .

test: clingo-lua54
	docker run --rm -v .:/srv clingo-lua54 test.lua
