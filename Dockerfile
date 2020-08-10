# Base image
FROM node:14.4.0-alpine3.10

# Set working directory
WORKDIR /AppBox

# Global
RUN yarn global add react-scripts
RUN yarn global add typescript
RUN yarn global add ts-node
RUN yarn global add gatsby-cli
RUN apk add --no-cache git

# Files
RUN mkdir -p /AppBox/Files/Users
RUN mkdir -p /AppBox/Files/Public

# System
RUN mkdir -p /AppBox/System/Backends

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

# Supervisor
WORKDIR /AppBox/System
RUN git clone https://github.com/AppBox-project/supervisor.git Supervisor
WORKDIR /AppBox/System/Supervisor
RUN yarn install
RUN yarn add typescript
RUN yarn build

# Siteserver
WORKDIR /AppBox/System
RUN git clone https://github.com/AppBox-project/siteserver.git SiteServer
WORKDIR /AppBox/System/SiteServer
RUN yarn install
RUN yarn add typescript

# add `/app/node_modules/.bin` to $PATH
ENV PATH /AppBox/System/Server/node_modules/.bin:$PATH
ENV PATH /AppBox/System/Supervisor/node_modules/.bin:$PATH
ENV PATH /AppBox/System/Client/node_modules/.bin:$PATH
ENV PATH /AppBox/System/SiteServer/node_modules/.bin:$PATH

ENV srvUrl https://appbox.vicvancooten.nl
ENV dbUrl '192.168.0.2:27017'

# start app
EXPOSE 8600 8601
WORKDIR /AppBox/System/Supervisor

CMD [ "yarn", "start" ]
