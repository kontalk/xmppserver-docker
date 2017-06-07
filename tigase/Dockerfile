# use BRANCH variable to provide source code branch
FROM debian:jessie-backports
LABEL "org.kontalk"="Kontalk devteam"
LABEL version="1.0"
LABEL description="Kontalk server base image"

# add testing and apt preferences
RUN echo "deb http://http.debian.net/debian testing main contrib non-free" >/etc/apt/sources.list.d/testing.list
COPY apt_preferences /etc/apt/preferences

# install packages
RUN apt-get -qq update
RUN apt-get -qq -y install wget git maven mysql-client openssl make g++ libkyotocabinet16 libkyotocabinet-dev
RUN apt-get -qq -y install -t jessie-backports openjdk-8-jdk certbot
RUN apt-get -qq -y install -t testing gnupg2
RUN update-java-alternatives -s java-1.8.0-openjdk-amd64

# install tools
ENV DOCKERIZE_VERSION v0.4.0
RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && rm dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz
RUN wget https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh \
    && mv wait-for-it.sh /usr/local/bin/wait-for-it \
    && chmod +x /usr/local/bin/wait-for-it

# create kontalk user
RUN useradd -ms /bin/bash kontalk

# will now work from the kontalk user
USER kontalk
WORKDIR /home/kontalk
# create data directory now so it will have the right owner
RUN mkdir -p data

# build kontalk server
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ARG BRANCH
ENV BRANCH ${BRANCH:-master}
RUN wget -qq -O - https://raw.githubusercontent.com/kontalk/tigase-kontalk/master/scripts/installer.sh | bash -s - kontalk ${BRANCH}

# install other requirements (jkyotocabinet)
USER root
COPY install-jkyotocabinet.sh post-install.sh /home/kontalk/
RUN chown kontalk:kontalk /home/kontalk/install-jkyotocabinet.sh /home/kontalk/post-install.sh
RUN chmod +x /home/kontalk/install-jkyotocabinet.sh /home/kontalk/post-install.sh
RUN ./install-jkyotocabinet.sh

# post-install operations
USER kontalk
RUN ./post-install.sh

# copy the entrypoint script
# we don't do this before to take advantage of caching
# when just changing the entrypoint script
USER root
COPY entrypoint.sh /home/kontalk/
RUN chown kontalk:kontalk /home/kontalk/entrypoint.sh
RUN chmod +x /home/kontalk/entrypoint.sh

# back to kontalk user and start everything up
USER kontalk
ENTRYPOINT ${HOME}/entrypoint.sh
