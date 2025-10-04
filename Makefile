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

compose-h2-up: build-hadoop2-jobimtext
	docker compose -f docker-compose-hadoop2-jobimtext.yml up -d

compose-h3-up: build-hadoop3-jobimtext
	docker compose -f docker-compose-hadoop3-jobimtext.yml up -d

compose-down:
	docker compose -f docker-compose-hadoop2-jobimtext.yml down
	docker compose -f docker-compose-hadoop3-jobimtext.yml down

compose-attach:
	sh attach-containers.sh

push-hadoop3: build-hadoop3
	docker push remstef/hadoop3

push-hadoop3-jobimtext: build-hadoop3-jobimtext
	docker push remstef/hadoop3-jobimtext

swarm-stack-deploy:
	docker stack deploy --compose-file compose-h3-jobimtext-swarm-explicit.yml jbth3

swarm-stack-rm:
	docker stack rm jbth3

swarm-stack-runtest:
	NAMENODE=$$(docker inspect --format '{{.Status.ContainerStatus.ContainerID}}' $$(docker service ps -q jbth3_namenode | head -n1)) \
	  && echo Namenode container id: $${NAMENODE} \
	  && docker exec $${NAMENODE} hdfs dfs -mkdir -p /user/hadoop/mouse \
	  && cat ./test-resources/mouse-corpus.txt | docker exec -i $${NAMENODE} hdfs dfs -put - /user/hadoop/mouse/corpus.txt \
	  && RUNSCRIPT=$$(docker exec $${NAMENODE} python2 generateHadoopScript.py -hl trigram -nb mouse | tail -n1) \
	  && echo scriptfile: $${RUNSCRIPT} \
	  && time docker exec -it $${NAMENODE} sh $${RUNSCRIPT}

