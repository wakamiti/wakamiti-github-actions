.PHONY: all install test clean workflows

all: install test clean

install:
	mkdir -p target/cache
	docker compose up -d --wait --quiet-pull
	cd target/cache && \
	git config --global advice.detachedHead "false" && \
	while read -r repo branch; do \
		repo_name=$$(echo $$repo | sed 's|/|-|g')@$$branch; \
		git clone --quiet --branch $$branch --single-branch git@github.com:$$repo.git $$repo_name && \
		cd $$repo_name && \
		git remote set-url origin https://github.com/$$repo && \
		cd ..; \
	done < ../../.caches
	$(MAKE) workflows

test:
	mkdir -p target/tests
	while read -r command id event workflow; do \
		[ -n "$$workflow" ] && w="-W ../../../workflows/$$workflow.yml" || w=""; \
		id=$$id-$$event; \
		cp -r test/$$id test/target/$$id; \
		log_file=target/tests/$$id.log; \
		echo "Test act $$command -C test/target/$$id -e ../../_data/events/$$event.json $$w"; \
		act $$command -C test/target/$$id -e ../../_data/events/$$event.json $$w > $$log_file 2>&1; \
		for job in $$(act $$command -C test/target/$$id -e ../../_data/events/$$event.json $$w --list | tail -n +2 | awk '{print $$2}'); do \
			if grep -q "[$$job] Job succeeded" $$log_file; then \
				echo "Job [$$job] SUCCESS"; \
			else \
				echo "Job [$$job] FAILED"; \
			fi; \
		done; \
	done < .tests

clean:
	docker compose down
	# Elimina contenedores de Docker
	for container in $$(docker ps --filter ancestor=catthehacker/ubuntu:java-tools-latest --format "{{.ID}}"); do \
		docker rm -f $$container; \
	done
	# Elimina todas las carpetas "target"
	find . -type d -name "target" -exec rm -rf {} +

workflows:
	mkdir -p target/cache/wakamiti-wakamiti-github-actions@main
	cd target/cache/wakamiti-wakamiti-github-actions@main && \
	rm -rf * && \
	cp -r ../../../.github/workflows .github/workflows && \
	git init --quiet && \
	git switch -c main --quiet