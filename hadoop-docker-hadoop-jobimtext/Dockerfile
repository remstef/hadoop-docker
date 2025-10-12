# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

ARG HADOOP_VERSION=3

FROM remstef/hadoop${HADOOP_VERSION}

USER root
WORKDIR /opt

# install pig
ARG PIG_URL=https://dlcdn.apache.org/pig/latest/pig-0.18.0.tar.gz
RUN curl -LSs -o pig.tar.gz $PIG_URL && tar zxf pig.tar.gz && rm pig.tar.gz && ln -s pig* pig && chown -R hadoop:users /opt/pig
ENV PATH="$PATH:/opt/pig/bin"
ENV PIG_HOME=/opt/pig
ENV PIG_CLASSPATH=/opt/hadoop/conf

# install spark
ARG SPARK_URL=https://dlcdn.apache.org/spark/spark-4.0.1/spark-4.0.1-bin-without-hadoop.tgz
RUN curl -LSs -o spark.tar.gz $SPARK_URL && tar zxf spark.tar.gz && rm spark.tar.gz && ln -s spark* spark && chown -R hadoop:users /opt/spark
ENV PATH="$PATH:/opt/spark/bin"
ENV SPARK_HOME="/opt/spark"
RUN echo "export JAVA_HOME=/opt/java/openjdk-${OPENJDK_VERSION}" > spark/conf/spark-env.sh \
    && echo "export HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop" >> spark/conf/spark-env.sh \
    && echo "export YARN_CONF_DIR=/opt/hadoop/etc/hadoop" >> spark/conf/spark-env.sh \
    && echo "export SPARK_DIST_CLASSPATH=$(hadoop classpath)" >> spark/conf/spark-env.sh \
    && echo "spark.yarn.appMasterEnv.JAVA_HOME=/opt/java/openjdk-${OPENJDK_VERSION}" > spark/conf/spark-defaults.conf \
    && echo "spark.executorEnv.JAVA_HOME=/opt/java/openjdk-${OPENJDK_VERSION}" >> spark/conf/spark-defaults.conf
  # && echo "spark.eventLog.dir file://${SPARK_HOME}/event_logs" >> $SPARK_HOME/conf/spark-defaults.conf \

# install jobimtext
ARG JOBIMTEXT_URL=http://ltdata1.informatik.uni-hamburg.de/jobimtext-resources/jobimtext.p/jobimtext_pipeline_0.1.5beta.tar.gz
RUN curl -LSs -o jobimtext.tar.gz $JOBIMTEXT_URL && tar zxf jobimtext.tar.gz && rm jobimtext.tar.gz && ln -s jobimtext* jobimtext && chown -R hadoop:users /opt/jobimtext
RUN apt update -q \
    && DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
      python2 \
      openssh-server \
      unzip \
    && apt clean

# python-setuptools
ARG PYTHON_SETUPTOOLS_URL=https://files.pythonhosted.org/packages/b2/40/4e00501c204b457f10fe410da0c97537214b2265247bc9a5bc6edd55b9e4/setuptools-44.1.1.zip
RUN curl -LSs -o setuptools.zip $PYTHON_SETUPTOOLS_URL \
    && unzip setuptools.zip \
    && rm setuptools.zip \
    && cd setuptools* \
    && python2 setup.py install \
    && cd .. \
    && rm -rf setuptools*

# python argparse
ARG PYTHON_ARGPARSE_URL=https://files.pythonhosted.org/packages/18/dd/e617cfc3f6210ae183374cd9f6a26b20514bbb5a792af97949c5aacddf0f/argparse-1.4.0.tar.gz
RUN curl -LSs -o argparse.tar.gz $PYTHON_ARGPARSE_URL \
    && tar zxf argparse.tar.gz \
    && rm argparse.tar.gz \
    && cd argparse* \
    && python2 setup.py install \
    && cd .. \
    && rm -rf argparse*

# configure openssh server
RUN mkdir -p /var/run/sshd \
    && mkdir -p /run/sshd \
    && echo "hadoop:hadoop" | chpasswd \
    && chsh -s /bin/bash hadoop \
    && sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config \
    && echo "PermitRootLogin no" >> /etc/ssh/sshd_config \
    && echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config \
    && echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config \
    && echo "Port 22" >> /etc/ssh/sshd_config \
    && echo "Protocol 2" >> /etc/ssh/sshd_config \
    && echo "AllowTcpForwarding yes" >> /etc/ssh/sshd_config \
    && echo "PermitTunnel yes" >> /etc/ssh/sshd_config \
    && echo "GatewayPorts yes" >> /etc/ssh/sshd_config \
    && echo "ClientAliveInterval 60" >> /etc/ssh/sshd_config \
    && echo "ClientAliveCountMax 3" >> /etc/ssh/sshd_config \
    && echo "AllowUsers hadoop" >> /etc/ssh/sshd_config \
    && echo 'ListenAddress 0.0.0.0' >> /etc/ssh/sshd_config \
    && echo "PermitUserEnvironment yes" >> /etc/ssh/sshd_config \
    && echo "ForceCommand cd /opt/jobimtext && exec bash -l" >> /etc/ssh/sshd_config

EXPOSE 22

RUN bash -c 'echo "[ -n \"\$BASH_VERSION\" ] && shopt -s globstar" >> /etc/profile'

COPY --chown=hadoop --chmod=755 scripts /opt/
RUN ln -s /opt/ssh-server.sh /usr/local/bin/ssh-server

WORKDIR /opt/jobimtext

USER hadoop
