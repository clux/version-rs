NAME=version
REPO=clux
VERSION=$(shell git rev-parse HEAD)
SEMVER_VERSION=$(shell grep -E "^version" Cargo.toml | awk -F"\"" '{print $$2}' | head -n 1)

version: version.rs
	docker run --rm \
		-v $$PWD:/volume \
		-v cargo-cache:/root/.cargo/registry \
		-t clux/muslrust:stable cargo build --release
	sudo chown $$USER:$$USER -R target
	mv target/x86_64-unknown-linux-musl/release/version .

build:
	docker build -t $(REPO)/$(NAME):$(VERSION) .

run:
	RUST_LOG=info cargo run

tag-latest:
	docker tag $(REPO)/$(NAME):$(VERSION) $(REPO)/$(NAME):latest
	docker push $(REPO)/$(NAME):latest

tag-version:
	docker push $(REPO)/$(NAME):$(VERSION)
	docker tag  $(REPO)/$(NAME):$(VERSION) $(REPO)/$(NAME):$(VERSION)

tag-semver:
	if curl -sSL https://registry.hub.docker.com/v1/repositories/$(REPO)/$(NAME)/tags | jq -r ".[].name" | grep -q $(SEMVER_VERSION); then \
		echo "Tag $(SEMVER_VERSION) already exists - not publishing" ; \
	else \
		docker tag $(REPO)/$(NAME):$(VERSION) $(REPO)/$(NAME):$(SEMVER_VERSION) ; \
		docker push $(REPO)/$(NAME):$(SEMVER_VERSION) ; \
	fi
