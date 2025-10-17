# About

This project offers single- or multi node [Apache Hadoop](https://hadoop.apache.org/) cluster docker images and docker compose files with [jobimtext](https://sourceforge.net/projects/jobimtext/), [Apache pig](https://pig.apache.org/) and [Apache Spark](https://spark.apache.org/) enabled.

# Quickstart

Run `make` to list [all targets](#makefile-targets).

Makefile targets are designed to run in sequential order. 

This repository offers two configurations:
* `explicit`: One docker container per hadoop service
* `shared`: One docker container may run multiple hadoop services

Both configurations can be run with `compose` in a single machine setup, or in a `swarm` as a multi-machine setup.

## Run single- or multi machine cluster with compose (local) or stack (swarm)

Start single machine hadoop cluster (Note: hadoop2 is available as a legacy version; hadoop3 is preferred).

Run make targets in sequential order, define the preferred configuration
```
make <config> compose-up compose-status

<config> = { h2-explicit, h3-explicit, h3-shared }

e.g.

make h3-shared compose-up compose-status
```

Start multi machine hadoop cluster (requires a docker swarm to be set up, @see [set up swarm](#set-up-docker-swarm); `shared` config is preferred).

```
make <config> stack-deploy stack-status

<config> = { h3-explicit-swarm, h3-shared-swarm }

e.g.

make h3-shared-swarm stack-deploy stack-status
```

Print information on how to open a socks proxy forward via ssh to access Hadoop's internal Web UIs:
```
make ssh-info
```

Connect to ssh server (gateway or headnode, depending on `<config>`; see respective compose file):
```
make ssh-connect

or 

make ssh-connect-proxy
```

Pass extra ssh arguments, e.g.
```
make ssh-connect ssh_args="-J <jumphost(s)>"

or 

make ssh-connect-proxy ssh_args="-J <jumphost(s)>"
```

Attach to the headnode container:
```
make <config> compose-attach-headnode

or 

make <config> swarm-attach-headnode
```

Attach to all compose containers (requires tmux to be installed):
```
make <config> compose-attach-all
```

Test yarn/hadoop (execute on any node, preferrably the headnode):
```
yarn jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar pi 10 15

yarn jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar wordcount <input> <output> && hdfs dfs -cat <output>/*
```

Test spark (execute on headnode, :q to quit):
```
spark-shell --master=yarn
```

Test pig (execute on headnode, \q to quit):
```
pig -
```

Test jobimtext (execute on headnode):
```
hdfs dfs -mkdir -p /user/hadoop/mouse
hdfs dfs -put mouse-corpus.txt /user/hadoop/mouse/corpus.txt
python2 generateHadoopScript.py -f 2 -w 3 -wf 2 -p 100 -wpfmin 2 -l 20 -af -nb -hl trigram -hm 5 -lines 1000 mouse
sh <generated-scriptfile>
```

Alternatively run automatic jobimtext test w/o being attached
```
make <config> compose-runtest

or

make <config> stack-runtest
```

Shutdown single- or multi machine cluster
```
make <config> compose-down

or

make <config> stack-rm
```

## Set up docker swarm

Required once (manual process, the following command prints the instructions):
```
make swarm-init-info
```

Check status of swarm nodes 
```
make swarm-status
```

Start multinode cluster on a docker swarm with compose file (here, example with 4 nodes, 1 manager & 3 workers, see `compose-h3-explicit-swarm.yml` and `compose-h3-shared-swarm.yml`; execute on the docker swarm manager; Note, to speed up deployment run initially `make pull-images`.)
```
make <config> stack-deploy

(cf. above)
```

## Makefile targets

```
list-targets (default)

check-file

h2-explicit
h3-explicit
h3-explicit-swarm
h3-shared
h3-shared-swarm

pull-images

compose-up
compose-status
compose-stats
compose-down
compose-headnodeid
compose-attach-headnode
compose-attach-all
compose-refreshnodes
compose-runtest

ssh-connect
ssh-connect-proxy
ssh-info / gateway-info

swarm-init-info
swarm-status

stack-deploy
stack-status
stack-rm
stack-headnodeid
stack-attach-headnode
stack-refreshnodes
stack-runtest

# for development purposes

buildx-hadoop-runner
buildx-push-hadoop-runner
buildx-hadoop
buildx-push-hadoop
buildx-hadoop-jobimtext
buildx-push-hadoop-jobimtext

(deprecated, prefer multi-platform builds with buildx)
build-hadoop-runner
build-hadoop
build-hadoop-jobimtext

push-hadoop-runner
push-hadoop
push-hadoop-jobimtext
```

## Notes:
* Everything provided here is experimental and is not guaranteed to be feature complete.
* ATTENTION: Data is not persisted, once the cluster's containers are shutdown, the data within the hdfs is lost!

## Docker images
* https://hub.docker.com/repository/docker/remstef/hadoop3-jobimtext
* https://hub.docker.com/repository/docker/remstef/hadoop3
* https://hub.docker.com/repository/docker/remstef/hadoop-runner

(Legacy Hadoop Version 2)
* https://hub.docker.com/repository/docker/remstef/hadoop2
* https://hub.docker.com/repository/docker/remstef/hadoop2-jobimtext

## Attribution
Dockerfiles taken from the Apache Hadoop project:
* https://github.com/apache/hadoop/tree/docker-hadoop-2
* https://github.com/apache/hadoop/tree/docker-hadoop-3
* https://github.com/apache/hadoop/tree/docker-hadoop-runner-jdk17-u2204

Descriptions from https://hub.docker.com/r/apache/hadoop are valid for 

* https://hub.docker.com/r/remstef/hadoop3 
* https://hub.docker.com/r/remstef/hadoop2 
* https://hub.docker.com/r/remstef/hadoop3-jobimtext 

images too.

## References:
* https://hadoop.apache.org/
* https://sourceforge.net/projects/jobimtext/
* https://pig.apache.org/
* https://spark.apache.org/



