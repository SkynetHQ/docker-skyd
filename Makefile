name=skyd-container
version=1.6.0

default: release

all: release pi dev

release:
	docker build -f Dockerfile \
		--build-arg SKYD_VERSION=$(version) \
		-t $(name) -t skynetlabs/skyd:$(version) -t skynetlabs/skyd:latest \
		.

pi:
	docker build -f pi/Dockerfile \
		--build-arg SKYD_VERSION=$(version) \
		-t $(name) -t skynetlabs/skyd:pi-$(version) -t skynetlabs/skyd:pi-latest \
		.

dev:
	docker build -f dev/Dockerfile \
		--build-arg "SHA=$(sha)" \
		--build-arg "TAG=$(tag)" \
		-t $(name) -t skynetlabs/skyd:dev \
		.

debug:
	docker build -f debug/Dockerfile -t $(name) -t skynetlabs/skyd:debug .

ci:
	docker build -f ci/Dockerfile -t $(name) -t skynetlabs/skyd:ci .

stop:
	docker stop $(docker ps -a -q --filter "name=$(name)") && docker rm $(docker ps -a -q --filter "name=$(name)")

.PHONY: all default release pi dev debug ci stop 
