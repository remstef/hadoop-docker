# IMAGE_NAME ?= hadoopv3-cluster
# DOCKERFILE ?= Dockerfile

.PHONY: build-haddop-runner

# build:
# 	docker build -t $(IMAGE_NAME) -f $(DOCKERFILE) .

build-haddop-runner:
	docker build -t remstef/hadoop-runner --build-arg OPENJDK_VERSION=21-jdk --build-arg OPENJDK_VERSION_HADOOP=11-jdk ./hadoop-docker-hadoop-runner-jdk8_jdk17-u2204

build-haddop2: build-haddop-runner
	docker build -t remstef/hadoop2 ./hadoop-docker-hadoop-2

build-haddop3: build-haddop-runner
	docker build -t remstef/hadoop3 ./hadoop-docker-hadoop-3

build-haddop2-jobimtext: build-haddop2
	docker build -t remstef/hadoop2-jobimtext --build-arg HADOOP_VERSION=2 ./hadoop-docker-hadoop-jobimtext

build-haddop3-jobimtext: build-haddop3
	docker build -t remstef/hadoop3-jobimtext --build-arg HADOOP_VERSION=3 ./hadoop-docker-hadoop-jobimtext

cluster-h2-compose-up: build-haddop2-jobimtext
	docker compose -f docker-compose-hadoop2-jobimtext.yml up -d

cluster-h3-compose-up: build-haddop3-jobimtext
	docker compose -f docker-compose-hadoop3-jobimtext.yml up -d

cluster-compose-down:
	docker compose -f docker-compose-hadoop2-jobimtext.yml down
	docker compose -f docker-compose-hadoop3-jobimtext.yml down

cluster-attach:
	sh attach-containers.sh
