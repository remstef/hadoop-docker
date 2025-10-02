#!/bin/bash

docker exec -i hadoopv3-cluster-namenode-1 hdfs dfs -mkdir -p /user/hadoop/mouse
docker exec -i hadoopv3-cluster-namenode-1 hdfs dfs -put mouse-corpus.txt /user/hadoop/mouse/corpus.txt
docker exec -i hadoopv3-cluster-namenode-1 sh mouse_trigram_s0.0_f2_w2_wf2_wpfmax1000_wpfmin2_p1000_sc_log_scored_LMI_simsort_ms_2_l200.sh