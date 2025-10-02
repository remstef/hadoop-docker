Makefile targets:

```
build-haddop-runner

build-haddop2

build-haddop3

build-haddop2-jobimtext

build-haddop3-jobimtext

cluster-h2-compose-up

cluster-h2-compose-down

cluster-h3-compose-up

cluster-h3-compose-down

cluster-attach
```

run cluster with (either or)
```
make cluster-h2-compose-up

or

make cluster-h3-compose-up
```

attach to containers:
```
make cluster-attach
```

test yarn/hadoop:
```
yarn jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar pi 10 15
```

test spark (execute on namenode, :q to quit):
```
spark-shell --master=yarn
```

test pig (execute on namenode, \q to quit):
```
pig -
```

test jobimtext (execute on namenode):
```
hdfs dfs -mkdir -p /user/hadoop/mouse
hdfs dfs -put mouse-corpus.txt /user/hadoop/mouse/corpus.txt
sh mouse_trigram_s0.0_f2_w2_wf2_wpfmax1000_wpfmin2_p1000_sc_log_scored_LMI_simsort_ms_2_l200.sh
```

shutdown cluster
```
make cluster-compose-down
```