# ------------------------------------------------------------------
# Makefile for Hadoop with Docker Containers (one or multiple nodes)
# Author: Steffen Remus
# Date: 2025-10-01
# Description: 
#   This Makefile specifies important commands to 
#   build, start, stop, and interact with the hadoop cluster.
# ------------------------------------------------------------------

# Specify the shell to use for all commands
SHELL := /bin/bash

# all targets are phony
.PHONY: $(MAKECMDGOALS)

# all targets should be silent
.SILENT: $(MAKECMDGOALS)

# Default compose file if none specified
file ?= docker-compose.yml

# Default hadoop version
hadoop_version ?= 3

# Default headnode name
headnode ?= namenode

# Default compose file if none specified
stack ?= jbth3

# default target
list-targets: 
	@echo "Available targets: (run with make <target-name>)"
	@make -n -p | grep -E -o '^[a-zA-Z0-9_\-]+:' | sed 's/://' | grep -v Makefile | sort

h2-explicit:
	@$(eval hadoop_version := 2)
	@$(eval file := compose-h2-explicit.yml)
	@echo "Using Hadoop version $(hadoop_version), and compose file $(file)"
	@echo "NOTE: hadoop v2 is a legacy version."

h3-explicit:
	@$(eval hadoop_version := 3)
	@$(eval file := compose-h3-explicit.yml)
	@echo "Using Hadoop version $(hadoop_version), and compose file $(file)"

h3-shared:
	@$(eval hadoop_version := 3)
	@$(eval file := compose-h3-shared.yml)
	@$(eval headnode := headnode)
	@echo "Using Hadoop version $(hadoop_version), and compose file $(file)"

h3-explicit-swarm:
	@$(eval hadoop_version := 3)
	@$(eval file := compose-h3-explicit-swarm.yml)
	@echo "Using Hadoop version $(hadoop_version), and compose file $(file)"

h3-shared-swarm:
	@$(eval hadoop_version := 3)
	@$(eval file := compose-h3-shared-swarm.yml)
	@$(eval headnode := headnode)
	@echo "Using Hadoop version $(hadoop_version), and compose file $(file)"

check-file:
	@if [ ! -f "$(file)" ]; then \
		echo "Error: File '$(file)' does not exist"; \
		exit 1; \
	fi; \

build-hadoop-runner:
ifeq ($(hadoop_version),3)
	docker build -t remstef/hadoop-runner:$(hadoop_version) --build-arg OPENJDK_VERSION=21-jdk --build-arg OPENJDK_VERSION_HADOOP=11-jdk ./hadoop-docker-hadoop-runner-jdk8_jdk17-u2204
else
	docker build -t remstef/hadoop-runner:$(hadoop_version) ./hadoop-docker-hadoop-runner-jdk8_jdk17-u2204
endif

push-hadoop-runner:
	docker push remstef/hadoop-runner:$(hadoop_version)

buildx-hadoop-runner:
ifeq ($(hadoop_version),3)
	docker buildx build -t remstef/hadoop-runner:$(hadoop_version) --build-arg OPENJDK_VERSION=21-jdk --build-arg OPENJDK_VERSION_HADOOP=11-jdk --platform linux/arm64,linux/amd64 ./hadoop-docker-hadoop-runner-jdk8_jdk17-u2204
else
	docker buildx build -t remstef/hadoop-runner:$(hadoop_version) --platform linux/arm64,linux/amd64 ./hadoop-docker-hadoop-runner-jdk8_jdk17-u2204
endif

buildx-push-hadoop-runner:
ifeq ($(hadoop_version),3)
	docker buildx build -t remstef/hadoop-runner:$(hadoop_version) --build-arg OPENJDK_VERSION=21-jdk --build-arg OPENJDK_VERSION_HADOOP=11-jdk --platform linux/arm64,linux/amd64 --push ./hadoop-docker-hadoop-runner-jdk8_jdk17-u2204
else
	docker buildx build -t remstef/hadoop-runner:$(hadoop_version) --platform linux/arm64,linux/amd64 --push ./hadoop-docker-hadoop-runner-jdk8_jdk17-u2204
endif

build-hadoop:
	docker build -t remstef/hadoop$(hadoop_version) ./hadoop-docker-hadoop-$(hadoop_version)

push-hadoop:
	docker push remstef/hadoop$(hadoop_version)

buildx-hadoop:
	docker buildx build -t remstef/hadoop$(hadoop_version)  --platform linux/arm64,linux/amd64 ./hadoop-docker-hadoop-$(hadoop_version)

buildx-push-hadoop:
	docker buildx build -t remstef/hadoop$(hadoop_version)  --platform linux/arm64,linux/amd64 --push ./hadoop-docker-hadoop-$(hadoop_version)

build-hadoop-jobimtext:
	docker build -t remstef/hadoop$(hadoop_version)-jobimtext --build-arg HADOOP_VERSION=$(hadoop_version) ./hadoop-docker-hadoop-jobimtext

push-hadoop-jobimtext:
	docker push remstef/hadoop$(hadoop_version)-jobimtext

buildx-hadoop-jobimtext:
	docker buildx build -t remstef/hadoop$(hadoop_version)-jobimtext --build-arg HADOOP_VERSION=$(hadoop_version) --platform linux/arm64,linux/amd64 ./hadoop-docker-hadoop-jobimtext

buildx-push-hadoop-jobimtext:
	docker buildx build -t remstef/hadoop$(hadoop_version)-jobimtext --build-arg HADOOP_VERSION=$(hadoop_version) --platform linux/arm64,linux/amd64 --push ./hadoop-docker-hadoop-jobimtext

pull-images:
	docker pull remstef/hadoop$(hadoop_version)
	docker pull remstef/hadoop$(hadoop_version)-jobimtext

compose-up: check-file
	docker compose -f $(file) up -d
	# sleep a couple of seconds to give the container some time to start 
	# before exiting make and potentially invoking the next target
	@sleep 3

compose-status: check-file
	docker compose -f $(file) ps -a

compose-stats: check-file
	docker compose -f $(file) stats

compose-down: check-file
	docker compose -f $(file) down

compose-attach-headnode: check-file compose-headnodeid
	docker exec -ti $(HEADNODE_CONTAINER) bash

compose-attach-all: check-file
	sh attach-containers.sh $(file)

compose-headnodeid: check-file
	@$(eval export HEADNODE_CONTAINER := $(shell docker compose -f $(file) ps $(headnode) -q))
	@echo $(headnode) container id: $(HEADNODE_CONTAINER)	

compose-refreshnodes: compose-headnodeid
	docker exec $(HEADNODE_CONTAINER) hdfs dfsadmin -refreshNodes

run-jbt-test:
ifndef HEADNODE_CONTAINER
	@echo ""
	@echo "Headnode container ID is not specified."
	@echo "Run"
	@echo "  make run-jbt-test HEADNODE_CONTAINER=<container-id>"
	@echo "or"
	@echo "  make {h2,h3} compose-runtest"
	@echo "or"
	@echo "  make {h3-swarm} stack-runtest"
	@echo ""
	@exit 1
endif
	docker exec $(HEADNODE_CONTAINER) hdfs dfs -mkdir -p /user/hadoop/mouse \
	  && cat ./test-resources/mouse-corpus.txt | docker exec -i $(HEADNODE_CONTAINER) hdfs dfs -put - /user/hadoop/mouse/corpus.txt \
	  ; RUNSCRIPT=$$(docker exec $(HEADNODE_CONTAINER) python2 generateHadoopScript.py -f 2 -w 2 -wf 2 -p 100 -wpfmin 2 -l 20 -af -nb -hl $(hl) -hm $(hm) -lines 1000 mouse | tail -n1) \
	  && echo scriptfile: $${RUNSCRIPT} \
		&& HDFSOUTDIR=$$(docker exec $(HEADNODE_CONTAINER) cat $${RUNSCRIPT} | tail -n 1 | grep -o -E "OUT=[^ ]*" | sed 's/OUT=//') \
		&& echo hdfs output directory: $${HDFSOUTDIR} \
	  && time docker exec $(HEADNODE_CONTAINER) sh $${RUNSCRIPT} \
		; docker exec $(HEADNODE_CONTAINER) hdfs dfs -text "$${HDFSOUTDIR}/*" | grep "^mouse" | head -n 10

compose-runtest: compose-headnodeid
	@$(eval export hl ?= trigram)
	@$(eval export hm ?= 5)
	$(MAKE) run-jbt-test

swarm-init-info:
	@echo "==== ==== ==== ===="
	@echo "### ### ### ### ###"
	@echo ""
	@echo "Follow the instructions below to setup a docker swarm."
	@echo "Details can also be found under the following links:"
	@echo "    https://docs.docker.com/engine/swarm/swarm-tutorial/"
	@echo "    https://docs.docker.com/engine/swarm/stack-deploy/"
	@echo ""
	@echo "Init the manager: "
	@echo ""
	@echo "    docker swarm init --advertise-addr <docker-manager-ip-address>"
	@echo ""
	@echo "Use the join token to add worker nodes."
	@echo "On each worker run: "
	@echo ""
	@echo "    docker swarm join --token <join-token> <docker-manager-ip-address>:2377"
	@echo ""
	@echo "Assign hadoop roles for the manager and workers."
	@echo "On the manager execute:"
	@echo ""
	@echo "    docker node update --label-add hadooprole=master <docker-manager-node-name>"
	@echo ""
	@echo "    for each worker node execute (on the manager): "
	@echo ""
	@echo "    docker node update --label-add hadooprole=worker{i} <docker-node-name>"
	@echo ""
	@echo "The example 'compose-h3-swarm.yml' file expects 4 labelled nodes"
	@echo "(master, worker1, worker2, worker3) which are supposed to be different physical machines."
	@echo ""
	@echo "Check the status with: "
	@echo ""
	@echo "    make swarm-status"
	@echo ""
	@echo "Leave swarm (execute on every node):"
	@echo ""
	@echo "    docker swarm leave"
	@echo ""
	@echo "### ### ### ### ###"
	@echo "==== ==== ==== ===="

swarm-status:
	@echo "Swarm info:"
	docker info | grep Swarm -A 23
	@echo ""
	@echo "Node info:"
	docker node ls
	@echo ""
	@echo "Node label info:"
	docker node ls --format '{{.Hostname}}' | while read h; do echo "$${h}:"; docker node inspect $${h} -f '{{ range $$k, $$v := .Spec.Labels }}  {{ $$k }}={{ $$v }}  {{ end }}'; done
	@echo ""

stack-deploy: check-file
	docker stack deploy -c $(file) -d --prune $(stack)

stack-rm:
	docker stack rm $(stack)

stack-headnodeid: 
# 	HEADNODE_CONTAINER := $$(docker inspect --format '{{.Status.ContainerStatus.ContainerID}}' $$(docker service ps -q $(stack)_$(headnode) | head -n1)) \
# 		&& echo Namenode container id: \
# 		&& echo $${HEADNODE_CONTAINER}
	@$(eval export HEADNODE_CONTAINER := $(shell docker inspect --format '{{.Status.ContainerStatus.ContainerID}}' $(shell docker service ps -q $(stack)_$(headnode) | head -n1)))
	@echo $(headnode) container id: $(HEADNODE_CONTAINER)	

stack-attach-headnode: stack-headnodeid
	docker exec -ti ${HEADNODE_CONTAINER} bash

stack-runtest: stack-headnodeid
	@$(eval export hl ?= trigram)
	@$(eval export hm ?= 5)
	$(MAKE) run-jbt-test

stack-refreshnodes: stack-headnodeid
	docker exec $(HEADNODE_CONTAINER) hdfs dfsadmin -refreshNodes
	
stack-status:
	@echo "Services"
	docker service ls
	@echo ""
	docker service ps --no-trunc $$(docker service ls -q)
	@echo ""
	@echo "Run the following commands to investigate services:"
	@echo "  docker service ps <service-name>"
	@echo "  docker service inspect <service-name> --pretty"
	@echo "  docker service logs <service-name>"
	@echo ""

ssh-info:
	@echo ""
	@echo "To connect to the ssh gateway server (headnode) type:"
	@echo "  Replace <host> with 0.0.0.0 or ::, or 12.0.0.1, or ::1, or $${HOSTNAME},"
	@echo "  or any IP address docker binds ports to on the host system."
	@echo ""
	@echo "  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 hadoop@<host-or-ip>"
	@echo ""
	@echo "If you did not supply a public key, enter the password defined in the respective compose file (default 'hadoop')."
	@echo ""
	@echo "If this is a server, run on your client:"
	@echo ""
	@echo "  ssh -J $${HOSTNAME} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 hadoop@<host-or-ip>"
	@echo ""
	@echo "  (add more jumphosts if necessary, e.g. -J jumphost1,jumphost2,$${HOSTNAME})"
	@echo ""
	@echo "Use -D to open a SOCKS proxy, without opening a shell (-N), and running ssh in the background (-f)."
	@echo ""
	@echo "  ssh -D 1080 -N -f -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 hadoop@<host-or-ip>"
	@echo ""
	@echo "Enter the SOCKS proxy details (localhost:1080) in your browser (activate \"use proxy DNS\")."
	@echo "Addresses:"
	@echo "  http://resourcemanager:8088"
	@echo "  http://historyserver:19888"
	@echo "  http://namenode:9870"
	@echo "  http://sparkmaster:4040"
	@echo "  http://nodemanager:8042 (nodemanager{1-3} in swarm mode)"
	@echo "  http://datanode:9864 (datanode{1-3} in swarm mode)"
	@echo ""

gateway-info: ssh-info

# make ssh-connect ssh_args=-v 
ssh-connect:
	@echo "SSH extra args: $(ssh_args)"
	ssh $(ssh_args) -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 sshuser@0.0.0.0

ssh-connect-proxy:
	@echo "SSH extra args: $(ssh_args)"
	ssh $(ssh_args) -D 1080 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 sshuser@0.0.0.0

