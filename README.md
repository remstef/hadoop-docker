```

docker build -t remstef/hadoop-runner ./hadoop-docker-hadoop-runner-jdk8-u2204

docker build -t remstef/hadoop2 ./hadoop-docker-hadoop-2

docker build -t remstef/hadoop3 ./hadoop-docker-hadoop-3

docker build -t remstef/hadoop3-jobimtext --build-arg HADOOP_VERSION=3 ./hadoop-docker-hadoop-jobimtext

docker build -t remstef/hadoop2-jobimtext --build-arg HADOOP_VERSION=2 ./hadoop-docker-hadoop-jobimtext
```

attach to containers:
```
sh attach-containers.sh
```

test spark (execute on any node, :q to quit):
```
spark-shell --master=yarn
```

test pig (execute on any node, \q to quit):
```
pig
```

test jobimtext (execute on any node):
```
hdfs dfs -mkdir -p /user/hadoop/mouse
hdfs dfs -put mouse-corpus.txt /user/hadoop/mouse/corpus.txt
sh mouse_trigram_s0.0_f2_w2_wf2_wpfmax1000_wpfmin2_p1000_sc_log_scored_LMI_simsort_ms_2_l200.sh
```
