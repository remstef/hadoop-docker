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

# Default headnode name
headnode ?= namenode

# # Default Docker images
# img_hadoop_runner ?: remstef/hadoop-runner:3
# img_hadoop ?: remstef/hadoop3
# img_hadoop_jobimtext ?: rremstef/hadoop3-jobimtext

# default target
list-targets: 
	@echo "Available targets: (run with make <target-name>)"
	@make -n -p | grep -E -o '^[a-zA-Z0-9_\-]+:' | sed 's/://' | grep -v Makefile | sort

h3:
	@$(eval file := docker-compose-hadoop3-jobimtext.yml)
	@echo "Set compose file to: $(file)"

h2:
	@$(eval file := docker-compose-hadoop2-jobimtext.yml)
	@echo "Set compose file to: $(file)"

build-hadoop2-runner:
	docker build -t remstef/hadoop-runner:2 ./hadoop-docker-hadoop-runner-jdk8_jdk17-u2204

build-hadoop3-runner:
	docker build -t remstef/hadoop-runner:3 --build-arg OPENJDK_VERSION=21-jdk --build-arg OPENJDK_VERSION_HADOOP=11-jdk ./hadoop-docker-hadoop-runner-jdk8_jdk17-u2204

build-hadoop2: build-hadoop2-runner
	docker build -t remstef/hadoop2 ./hadoop-docker-hadoop-2

build-hadoop3: build-hadoop3-runner
	docker build -t remstef/hadoop3 ./hadoop-docker-hadoop-3

build-hadoop2-jobimtext: build-hadoop2
	docker build -t remstef/hadoop2-jobimtext --build-arg HADOOP_VERSION=2 ./hadoop-docker-hadoop-jobimtext

build-hadoop3-jobimtext: build-hadoop3
	docker build -t remstef/hadoop3-jobimtext --build-arg HADOOP_VERSION=3 ./hadoop-docker-hadoop-jobimtext

pull-hadoop3:
	docker pull remstef/hadoop3
	docker pull remstef/hadoop3-jobimtext

compose-h2-up:
	docker compose -f docker-compose-hadoop2-jobimtext.yml up -d

compose-h3-up:
	docker compose -f docker-compose-hadoop3-jobimtext.yml up -d

compose-up:
	docker compose -f $(file) up -d

compose-h2-runtest:
	NAMENODE=$$(docker compose -f docker-compose-hadoop2-jobimtext.yml ps namenode -q) \
	  && echo Namenode container id: $${NAMENODE} \
	  && docker exec $${NAMENODE} hdfs dfs -mkdir -p /user/hadoop/mouse \
	  && cat ./test-resources/mouse-corpus.txt | docker exec -i $${NAMENODE} hdfs dfs -put - /user/hadoop/mouse/corpus.txt \
	  ; RUNSCRIPT=$$(docker exec $${NAMENODE} python2 generateHadoopScript.py -hl trigram -nb mouse | tail -n1) \
	  && echo scriptfile: $${RUNSCRIPT} \
	  && time docker exec -it $${NAMENODE} sh $${RUNSCRIPT} \
		; docker exec $${NAMENODE} hdfs dfs -text mouse_trigram__FreqSigLMI__PruneContext_s_0.0_w_2_f_2_wf_2_wpfmax_1000_wpfmin_2_p_1000__AggrPerFt__SimCount_sc_log_scored_ac_False__SimSort_v2limit_200_minsim_2/* | grep "^mouse" | head -n 10

compose-h3-runtest:
	NAMENODE=$$(docker compose -f docker-compose-hadoop3-jobimtext.yml ps namenode -q) \
	  && echo Namenode container id: $${NAMENODE} \
	  && docker exec $${NAMENODE} hdfs dfs -mkdir -p /user/hadoop/mouse \
	  && cat ./test-resources/mouse-corpus.txt | docker exec -i $${NAMENODE} hdfs dfs -put - /user/hadoop/mouse/corpus.txt \
	  ; RUNSCRIPT=$$(docker exec $${NAMENODE} python2 generateHadoopScript.py -hl trigram -nb mouse | tail -n1) \
	  && echo scriptfile: $${RUNSCRIPT} \
	  && time docker exec -it $${NAMENODE} sh $${RUNSCRIPT} \
		; docker exec $${NAMENODE} hdfs dfs -text mouse_trigram__FreqSigLMI__PruneContext_s_0.0_w_2_f_2_wf_2_wpfmax_1000_wpfmin_2_p_1000__AggrPerFt__SimCount_sc_log_scored_ac_False__SimSort_v2limit_200_minsim_2/* | grep "^mouse" | head -n 10

compose-runtest:
	HEADNODE=$$(docker compose -f $(file) ps $(headnode) -q) \
	  && echo headnode container id: $${HEADNODE} \
	  && docker exec $${HEADNODE} hdfs dfs -mkdir -p /user/hadoop/mouse \
	  && cat ./test-resources/mouse-corpus.txt | docker exec -i $${HEADNODE} hdfs dfs -put - /user/hadoop/mouse/corpus.txt \
	  ; RUNSCRIPT=$$(docker exec $${HEADNODE} python2 generateHadoopScript.py -hl trigram -nb mouse | tail -n1) \
	  && echo scriptfile: $${RUNSCRIPT} \
	  && time docker exec -it $${HEADNODE} sh $${RUNSCRIPT} \
		; docker exec $${HEADNODE} hdfs dfs -text mouse_trigram__FreqSigLMI__PruneContext_s_0.0_w_2_f_2_wf_2_wpfmax_1000_wpfmin_2_p_1000__AggrPerFt__SimCount_sc_log_scored_ac_False__SimSort_v2limit_200_minsim_2/* | grep "^mouse" | head -n 10

compose-down:
	docker compose -f docker-compose-hadoop2-jobimtext.yml down
	docker compose -f docker-compose-hadoop3-jobimtext.yml down
	docker compose -f $(file) down

compose-attach:
	sh attach-containers.sh

push-hadoop3: build-hadoop3
	docker push remstef/hadoop3

push-hadoop3-jobimtext: build-hadoop3-jobimtext
	docker push remstef/hadoop3-jobimtext

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
	@echo "The example 'docker-compose-h3-jobimtext-swarm-explicit.yml' file expects 4 labelled nodes"
	@echo "(master, worker1, worker2, worker3) which should ideally be different physical machines."
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

swarm-stack-deploy:
	docker stack deploy --compose-file docker-compose-h3-jobimtext-swarm-explicit.yml jbth3

swarm-stack-rm:
	docker stack rm jbth3

swarm-stack-namenode:
	NAMENODE=$$(docker inspect --format '{{.Status.ContainerStatus.ContainerID}}' $$(docker service ps -q jbth3_namenode | head -n1)) \
		&& echo Namenode container id: \
		&& echo $${NAMENODE}

swarm-stack-attach-namenode:
	NAMENODE=$$(docker inspect --format '{{.Status.ContainerStatus.ContainerID}}' $$(docker service ps -q jbth3_namenode | head -n1)) \
	  && echo Namenode container id: $${NAMENODE} \
	  && docker exec -ti $${NAMENODE} bash

swarm-stack-runtest:
	NAMENODE=$$(docker inspect --format '{{.Status.ContainerStatus.ContainerID}}' $$(docker service ps -q jbth3_namenode | head -n1)) \
	  && echo Namenode container id: $${NAMENODE} \
	  && docker exec $${NAMENODE} hdfs dfs -mkdir -p /user/hadoop/mouse \
	  && cat ./test-resources/mouse-corpus.txt | docker exec -i $${NAMENODE} hdfs dfs -put - /user/hadoop/mouse/corpus.txt \
	  ; RUNSCRIPT=$$(docker exec $${NAMENODE} python2 generateHadoopScript.py -hl trigram -nb mouse | tail -n1) \
	  && echo scriptfile: $${RUNSCRIPT} \
	  && time docker exec -it $${NAMENODE} sh $${RUNSCRIPT} \
		; docker exec $${NAMENODE} hdfs dfs -text mouse_trigram__FreqSigLMI__PruneContext_s_0.0_w_2_f_2_wf_2_wpfmax_1000_wpfmin_2_p_1000__AggrPerFt__SimCount_sc_log_scored_ac_False__SimSort_v2limit_200_minsim_2/* | grep "^mouse" | head -n 10

swarm-stack-status:
	docker service ls
	@echo ""
	@echo "Run the following commands to investigate services:"
	@echo "  docker service ps <service-name>"
	@echo "  docker service inspect <service-name> --pretty"
	@echo "  docker service logs <service-name>"
	@echo ""

ssh-info:
	@echo ""
	@echo "To open a SOCKS proxy, type:"
	@echo ""
	@echo "  ssh -N -f -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 22222 -D 1080 hadoop@0.0.0.0"
	@echo ""
	@echo "If this is a server, run on your client:"
	@echo ""
	@echo "  ssh -N -f -J $${HOSTNAME} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 22222 -D 1080 hadoop@0.0.0.0"
	@echo ""
	@echo "  (add more jumphosts if necessary, e.g. -J jumphost1,jumphost2,$${HOSTNAME})"
	@echo ""
	@echo "Type in password 'hadoop'."
	@echo ""
	@echo "Enter the SOCKS proxy details (localhost:1080) in your browser (activate \"use proxy DNS\")."
	@echo "Addresses:"
	@echo "  http://resourcemanager:8088"
	@echo "  http://historyserver:19888"
	@echo "  http://namenode:9870"
	@echo "  http://nodemanager:8042 (nodemanager{1-3} in swarm mode)"
	@echo "  http://datanode:9864 (datanode{1-3} in swarm mode)"
	@echo ""

