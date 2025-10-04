# IMAGE_NAME ?= hadoopv3-cluster
# DOCKERFILE ?= Dockerfile

.PHONY: build-hadoop-runner

# build:
# 	docker build -t $(IMAGE_NAME) -f $(DOCKERFILE) .

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

cluster-h2-compose-up: build-hadoop2-jobimtext
	docker compose -f docker-compose-hadoop2-jobimtext.yml up -d

cluster-h3-compose-up: build-hadoop3-jobimtext
	docker compose -f docker-compose-hadoop3-jobimtext.yml up -d

cluster-compose-down:
	docker compose -f docker-compose-hadoop2-jobimtext.yml down
	docker compose -f docker-compose-hadoop3-jobimtext.yml down

cluster-compose-attach:
	sh attach-containers.sh

push-hadoop3: build-hadoop3
	docker push remstef/hadoop3

push-hadoop3-jobimtext: build-hadoop3-jobimtext
	docker push remstef/hadoop3-jobimtext

cluster-swarm-deploy:
	docker stack deploy --compose-file compose-h3-jobimtext-swarm-explicit.yml jbth3

cluster-swarm-rm:
	docker stack rm jbth3

cluster-swarm-runtest:
	NAMENODE=$$(docker inspect --format '{{.Status.ContainerStatus.ContainerID}}' $$(docker service ps -q jbth3_namenode | head -n1)) \
		&& echo Namenode container id: $${NAMENODE} \
 	  && docker exec -it $${NAMENODE} hdfs dfs -mkdir -p /user/hadoop/mouse \
 	  && cat ./test-resources/mouse-corpus.txt | docker exec -it $${NAMENODE} hdfs dfs -put - /user/hadoop/mouse/corpus.txt \
		&& RUNSCRIPT=$$(docker exec -it $${NAMENODE} python generateHadoopScript.py -hl trigram -nb mouse | tail -n1) \
 	  && echo scriptfile: $${RUNSCRIPT} \
		&& time docker exec -it $${NAMENODE} sh $${RUNSCRIPT} 
#  	  && docker cp mouse_trigram_s0.0_f2_w2_wf2_wpfmax1000_wpfmin2_p1000_sc_log_scored_LMI_simsort_ms_2_l200.sh $${NAMENODE}: runjbtjob.sh \
