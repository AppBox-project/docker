# Base image
FROM node:14.4.0-alpine3.13

# Set working directory
WORKDIR /AppBox

# Global
RUN yarn global add react-scripts
RUN yarn global add typescript
RUN yarn global add ts-node
RUN yarn global add pm2
RUN apk update
RUN apk add --no-cache git
RUN apk add --no-cache tzdata

# Python
ENV PYTHONUNBUFFERED=1
RUN apk add --update --no-cache python3 && ln -sf python3 /usr/bin/python
RUN python3 -m ensurepip
RUN pip3 install --no-cache --upgrade pip setuptools


# PhantomJS
WORKDIR /tmp
RUN apk add --update --no-cache curl &&\
  cd /tmp && curl -Ls https://github.com/dustinblackman/phantomized/releases/download/2.1.1/dockerized-phantomjs.tar.gz | tar xz &&\
  cp -R lib lib64 / &&\
  cp -R usr/lib/x86_64-linux-gnu /usr/lib &&\
  cp -R usr/share/fonts /usr/share &&\
  cp -R etc/fonts /etc &&\
  curl -k -Ls https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2 | tar -jxf - &&\
  cp phantomjs-2.1.1-linux-x86_64/bin/phantomjs /usr/local/bin/phantomjs &&\
  rm -rf /tmp/*

RUN apk add --no-cache bash
RUN echo 'alias appbox="yarn --cwd /AppBox/System/Supervisor"' >> ~/.bashrc

# Files
RUN mkdir -p /AppBox/Files/Users
RUN mkdir -p /AppBox/Files/Apps
RUN mkdir -p /AppBox/Files/Public

# System
RUN mkdir -p /AppBox/System/Backends
RUN mkdir -p /AppBox/System/Temp/Apps

# Client
RUN mkdir -p /System/Client
WORKDIR /AppBox/System
RUN git clone https://github.com/AppBox-project/client.git Client
WORKDIR /AppBox/System/Client
RUN yarn install
RUN yarn build

# Server
WORKDIR /AppBox/System
RUN git clone https://github.com/AppBox-project/server.git Server
WORKDIR /AppBox/System/Server
RUN yarn install
RUN yarn add typescript
RUN yarn build

# App-Server
WORKDIR /AppBox/System
RUN git clone https://github.com/AppBox-project/app-server.git App-Server
WORKDIR /AppBox/System/App-Server
RUN yarn install
RUN yarn add typescript
RUN yarn build

# Engine
WORKDIR /AppBox/System
RUN git clone https://github.com/AppBox-project/engine.git Engine
WORKDIR /AppBox/System/Engine
RUN yarn install
RUN yarn add typescript
RUN yarn build

# Supervisor
WORKDIR /AppBox/System
RUN git clone https://github.com/AppBox-project/supervisor.git Supervisor
WORKDIR /AppBox/System/Supervisor
RUN yarn install
RUN yarn add typescript
RUN yarn build

# add `/app/node_modules/.bin` to $PATH
ENV PATH /AppBox/System/Client/node_modules/.bin:$PATH
ENV PATH /AppBox/System/Server/node_modules/.bin:$PATH
ENV PATH /AppBox/System/Engine/node_modules/.bin:$PATH
ENV PATH /AppBox/System/Supervisor/node_modules/.bin:$PATH
ENV PATH /AppBox/System/App-Server/node_modules/.bin:$PATH

ENV PUBLICURL https://appbox.vicvancooten.nl
ENV DBURL '192.168.0.2:27017'
ENV TZ="Europe/Amsterdam"

# start app
EXPOSE 8600 8601
WORKDIR /AppBox/System/Supervisor

CMD [ "appbox", "start" ]
