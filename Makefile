
CUR_DIR := $(shell basename $(PWD))
SSH_DIR := $(HOME)/.ssh
CACHE_DIR := target/caches
ACT_CONTAINER := act
ACT_IMAGE := $(CUR_DIR)

.PHONY: all install test clean shutdown workflows list check

all: install test shutdown

install: workflows
	@mkdir -p target/.ssh
	cp -r $(HOME)/.ssh/* target/.ssh
	docker build -t $(ACT_IMAGE) --rm --build-arg DIR_NAME=wakamiti/$(CUR_DIR) .
	@if ! docker volume inspect act_docker > /dev/null 2>&1; then \
  		docker volume create act_docker; \
  	fi
	docker run -d --privileged --name $(ACT_CONTAINER) -w /docker \
		-e DOCKER_DRIVER=overlay2 \
		-e DOCKER_TLS_CERTDIR= \
		--cpus="2.0" \
        --memory="6g" \
        --memory-swap="6g" \
        --pids-limit=1024 \
		-v $(PWD)/src:/workflows \
		-v $(PWD)/test:/test \
		-v $(PWD)/target/caches:/caches \
		-v $(PWD)/target/test:/target \
		-v $(PWD)/target/logs/docker:/var/log/docker \
		-v $(PWD)/target/logs/test:/var/log/act \
		-v $(PWD)/target/logs/dockerd:/var/log/dockerd \
		-v act_docker:/var/lib/docker \
		$(ACT_IMAGE)
	$(MAKE) check

test: clean
	docker exec -ti $(ACT_CONTAINER) ./run

list:
	docker exec -ti $(ACT_CONTAINER) ./list

clean:
	docker exec -ti $(ACT_CONTAINER) ./clean

shutdown: clean
	docker exec -ti $(ACT_CONTAINER) docker compose down || true
	docker rm -f -v $(ACT_CONTAINER)
	rm -rf target

workflows:
	@mkdir -p $(CACHE_DIR)/wakamiti-$(CUR_DIR)@main
	cd $(CACHE_DIR)/wakamiti-$(CUR_DIR)@main && \
		rm -rf * && \
		cp -r ../../../.github .github && \
		git init --initial-branch=main && \
		git remote add origin https://github.com/wakamiti/$(CUR_DIR)

check:
	@echo "⏳ Esperando a que act esté sano..."
	@while [ "$$(docker inspect --format='{{.State.Health.Status}}' $(ACT_CONTAINER))" != "healthy" ]; do \
		sleep 2; \
		if [ "$$(docker inspect --format='{{.State.Health.Status}}' $(ACT_CONTAINER))" = "unhealthy" ]; then \
			echo "❌ Error: act is unhealthy."; \
			exit 1; \
		fi; \
	done
	@echo "✅ act container installed"
