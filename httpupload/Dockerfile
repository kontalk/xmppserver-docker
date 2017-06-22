# use BRANCH variable to provide source code branch
FROM debian:stretch-backports
LABEL "org.kontalk"="Kontalk devteam"
LABEL version="1.0"
LABEL description="Kontalk server HTTP upload component image"

# install packages
RUN apt-get -qq update && apt-get -qq -y --no-install-recommends install \
    wget git openssl python3 python3-pip python3-setuptools

# install tools
ENV DOCKERIZE_VERSION v0.5.0
RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && rm dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz
RUN wget https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh \
    && mv wait-for-it.sh /usr/local/bin/wait-for-it \
    && chmod +x /usr/local/bin/wait-for-it

# create kontalk user
RUN useradd --no-log-init -ms /bin/bash kontalk

# will now work from the kontalk user
USER kontalk
WORKDIR /home/kontalk

# install HTTP upload component
USER root
COPY install-httpupload.sh /home/kontalk/
RUN chown kontalk:kontalk /home/kontalk/install-httpupload.sh && chmod +x /home/kontalk/install-httpupload.sh
USER kontalk
RUN ./install-httpupload.sh

# install requirements
USER root
RUN pip3 install -r /home/kontalk/HttpUploadComponent/requirements.txt

# copy the entrypoint script
# we don't do this before to take advantage of caching
# when just changing the entrypoint script
COPY entrypoint.sh /home/kontalk/
RUN chown kontalk:kontalk /home/kontalk/entrypoint.sh && chmod +x /home/kontalk/entrypoint.sh

# back to kontalk user and start everything up
USER kontalk
RUN mkdir -p ${HOME}/disk
ENTRYPOINT ["/home/kontalk/entrypoint.sh"]
