NODE_MANAGERS ?= 3
NODE_WORKERS ?= 1
NODE_COUNT := $$(($(NODE_MANAGERS) + $(NODE_WORKERS)))
MAKEFILE := $(lastword $(MAKEFILE_LIST))


all: vagrant provision swarm
	$(MAKE) -f $(MAKEFILE) deploy traefik
	$(MAKE) -f $(MAKEFILE) deploy consul
	$(MAKE) -f $(MAKEFILE) deploy vault

vagrant:
	NODE_COUNT=$(NODE_COUNT) vagrant up

provision:
	@echo "\nInstalling Docker...\n"
	@for i in $(shell seq 1 $(NODE_COUNT)); do \
		docker-machine create \
			--driver generic \
			--generic-ip-address 192.168.250.1$$i \
			--generic-ssh-key ~/.vagrant.d/insecure_private_key \
			--generic-ssh-user vagrant \
			swarm$$i; \
	done

swarm: swarm-managers swarm-workers

swarm-managers:
	@echo "\nCreating Docker Swarm Cluster...\n"
	@eval $$(docker-machine env swarm1); \
	docker swarm init --advertise-addr $$(docker-machine ip swarm1); \
	join_cmd=$$(docker swarm join-token manager | grep "docker swarm join"); \
	for i in $$(seq 2 $(NODE_MANAGERS)); do \
		eval $$(docker-machine env swarm$$i); \
		$$join_cmd; \
	done

swarm-workers:
	@echo "\nAdding workers to the Swarm Cluster...\n"
	@eval $$(docker-machine env swarm1); \
	join_cmd=$$(docker swarm join-token worker | grep "docker swarm join"); \
	for i in $$(seq $$(($(NODE_MANAGERS) + 1)) $(NODE_COUNT)); do \
		eval $$(docker-machine env swarm$$i); \
		$$join_cmd; \
	done

clean:
	@for i in $$(seq 1 $(NODE_COUNT)); do \
		rm -rf ~/.docker/machine/machines/swarm$$i; \
	done
	NODE_COUNT=$(NODE_COUNT) vagrant destroy -f

connect:
	docker-machine env $(filter-out $@,$(MAKECMDGOALS))

deploy:
	docker stack deploy --compose-file stacks/$(filter-out $@,$(MAKECMDGOALS)).yml $(filter-out $@,$(MAKECMDGOALS))

rm:
	docker stack rm $(filter-out $@,$(MAKECMDGOALS))

%:
	@:
