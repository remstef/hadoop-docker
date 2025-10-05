## Run single node local cluster with compose

Start single node cluster (Note: hadoop2 is available as a legacy version; hadoop3 is preffered):
```
make compose-h2-up

or

make compose-h3-up
```

Attach to containers (requires tmux to be installed):
```
make cluster-attach
```

Test yarn/hadoop (execute on any node):
```
yarn jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar pi 10 15
```

Test spark (execute on namenode, :q to quit):
```
spark-shell --master=yarn
```

Test pig (execute on namenode, \q to quit):
```
pig -
```

Test jobimtext (execute on namenode):
```
hdfs dfs -mkdir -p /user/hadoop/mouse
hdfs dfs -put mouse-corpus.txt /user/hadoop/mouse/corpus.txt
python2 generateHadoopScript.py -hl trigram -nb mouse
sh mouse_trigram_s0.0_f2_w2_wf2_wpfmax1000_wpfmin2_p1000_sc_log_scored_LMI_simsort_ms_2_l200.sh
```

Alternatively run jobimtext test w/o being attached
```
make compose-h3-runtest
```

Shutdown single-node local cluster
```
make compose-down
```

## Run multinode node cluster with docker swarm

Required once:
```
make swarm-init
```

Start multinode cluster on a docker swarm with compose file (here, example with 4 nodes, 1 manager & 3 workers, see `docker-compose-h3-jobimtext-swarm-explicit.yml`; execute on the docker swarm manager; Note run `make pull-hadoop3` before to speed up deployment.)
```
make swarm-stack-deploy
```

Run jobimtext test:
```
make swarm-stack-runtest
```

Attach to namenode:
```
make swarm-stack-attach-namenode
```

Get namenode container id:
```
make swarm-stack-namenode
```

Shutdown multinode cluster:
```
make swarm-stack-rm
```

## Makefile targets

```
list-targets

build-hadoop2
build-hadoop2-jobimtext
build-hadoop2-runner
build-hadoop3
build-hadoop3-jobimtext
build-hadoop3-runner

push-hadoop3
push-hadoop3-jobimtext

pull-hadoop3

compose-h2-up
compose-h2-runtest
compose-h3-up
compose-h3-runtest
compose-attach
compose-down

swarm-init
swarm-stack-deploy
swarm-stack-namenode
swarm-stack-runtest
swarm-stack-attach-namenode
swarm-stack-rm
```

## Notes:
* Everything provided here is experimental and is not guaranteed to be feature complete.
* ATTENTION: Data is not persisted, once the cluster's containers are shutdown, the data within the hdfs is lost!

## Attribution
Dockerfiles taken from the Apache Hadoop project:
* https://github.com/apache/hadoop/tree/docker-hadoop-2
* https://github.com/apache/hadoop/tree/docker-hadoop-3
* https://github.com/apache/hadoop/tree/docker-hadoop-runner-jdk17-u2204



