IMAGE_NAME ?= sec-dev-app
IMAGE_TAG ?= latest
IMAGE := $(IMAGE_NAME):$(IMAGE_TAG)

.PHONY: build run stop logs test-container check-non-root check-health lint-docker scan-image verify test-service

build:
	docker build --pull -t $(IMAGE) .

run:
	docker compose -f compose.yaml --profile dev up -d

stop:
	docker compose -f compose.yaml --profile dev down

logs:
	docker compose -f compose.yaml --profile dev logs -f

test-container: check-non-root check-health

check-non-root: build
	@uid=$$(docker run --rm --entrypoint id $(IMAGE) -u); \
	echo "Container UID: $$uid"; \
	if [ "$$uid" -eq 0 ]; then \
		echo "ERROR: container runs as root (uid=0)"; \
		exit 1; \
	fi; \
	echo "OK: container runs as non-root user"

check-health: build
	@cid=$$(docker run -d --rm --name $(IMAGE_NAME)-test -p 8000:8000 $(IMAGE)); \
	echo "Started container $$cid"; \
	for i in $$(seq 1 30); do \
		status=$$(docker inspect -f '{{.State.Health.Status}}' $$cid 2>/dev/null || echo "starting"); \
		echo "Health status: $$status"; \
		if [ "$$status" = "healthy" ]; then \
			echo "Container is healthy"; \
			docker rm -f $$cid >/dev/null 2>&1 || true; \
			exit 0; \
		fi; \
		if [ "$$status" = "unhealthy" ]; then \
			echo "Container became unhealthy"; \
			docker logs $$cid || true; \
			docker rm -f $$cid >/dev/null 2>&1 || true; \
			exit 1; \
		fi; \
		sleep 2; \
	done; \
	echo "Health check timeout"; \
	docker logs $$cid || true; \
	docker rm -f $$cid >/dev/null 2>&1 || true; \
	exit 1

lint-docker:
	docker run --rm -i hadolint/hadolint hadolint - < Dockerfile

scan-image: build
	docker run --rm \
		-v /var/run/docker.sock:/var/run/docker.sock \
		aquasec/trivy:latest image --no-progress $(IMAGE)

verify:
	@./scripts/verify_container.sh

test-service:
	@./scripts/test_service.sh
