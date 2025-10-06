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

# default target
list-targets: 
	@echo "Available targets: (run with make <target-name>)"
	@make -n -p | grep -E -o '^[a-zA-Z0-9_\-]+:' | sed 's/://' | grep -v Makefile | sort

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
	
compose-h2-up: build-hadoop2-jobimtext
	docker compose -f docker-compose-hadoop2-jobimtext.yml up -d

compose-h3-up: build-hadoop3-jobimtext
	docker compose -f docker-compose-hadoop3-jobimtext.yml up -d

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

compose-down:
	docker compose -f docker-compose-hadoop2-jobimtext.yml down
	docker compose -f docker-compose-hadoop3-jobimtext.yml down

compose-attach:
	sh attach-containers.sh

push-hadoop3: build-hadoop3
	docker push remstef/hadoop3

push-hadoop3-jobimtext: build-hadoop3-jobimtext
	docker push remstef/hadoop3-jobimtext

swarm-init:
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
	@echo "The example 'docker-compose-h3-jobimtext-swarm-explicit.yml' file expects 4 labelled nodes 
	@echo "(master, worker1, worker2, worker3) which should ideally be different physical machines."
	@echo ""
	@echo "Check the status with: "
	@echo ""
	@echo "    make swarm-status
	@echo ""
	

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
