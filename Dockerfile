# Base image
FROM node:14.4.0-alpine3.10

# Set working directory
WORKDIR /AppBox

# Global
RUN yarn global add react-scripts
RUN yarn global add typescript
RUN yarn global add ts-node
RUN yarn global add gatsby-cli
RUN yarn global add pm2
RUN apk update
RUN apk add --no-cache git
RUN apk add --no-cache tzdata

# Segment for wkhtmltopdf
# install qt build packages #
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
	&& apk update \
	&& apk add gtk+ openssl glib fontconfig bash vim \
	&& apk add --virtual .deps git patch make g++ \
		libc-dev gettext-dev zlib-dev bzip2-dev libffi-dev pcre-dev \
		glib-dev atk-dev expat-dev libpng-dev freetype-dev fontconfig-dev \
		libxau-dev libxdmcp-dev libxcb-dev xf86bigfontproto-dev libx11-dev \
		libxrender-dev pixman-dev libxext-dev cairo-dev perl-dev \
		libxfixes-dev libxdamage-dev graphite2-dev icu-dev harfbuzz-dev \
		libxft-dev pango-dev gtk+-dev libdrm-dev \
		libxxf86vm-dev libxshmfence-dev wayland-dev mesa-dev openssl-dev \
	&& git clone --recursive https://github.com/wkhtmltopdf/wkhtmltopdf.git /tmp/wkhtmltopdf \
	&& cd /tmp/wkhtmltopdf \
	&& git checkout ccf91a0

COPY conf/* /tmp/wkhtmltopdf/qt/

RUN	cd /tmp/wkhtmltopdf/qt && \
	patch -p1 -i qt-musl.patch && \
	patch -p1 -i qt-musl-iconv-no-bom.patch && \
	patch -p1 -i qt-recursive-global-mutex.patch && \
	patch -p1 -i qt-font-pixel-size.patch && \
	patch -p1 -i qt-gcc6.patch && \
	sed -i "s|-O2|$CXXFLAGS|" mkspecs/common/g++.conf && \
	sed -i "/^QMAKE_RPATH/s| -Wl,-rpath,||g" mkspecs/common/g++.conf && \
	sed -i "/^QMAKE_LFLAGS\s/s|+=|+= $LDFLAGS|g" mkspecs/common/g++.conf && \
	CFLAGS=-w CPPFLAGS=-w CXXFLAGS=-w LDFLAGS=-w \
	./configure -confirm-license -opensource \
		-prefix /usr \
		-datadir /usr/share/qt \
		-sysconfdir /etc \
		-plugindir /usr/lib/qt/plugins \
		-importdir /usr/lib/qt/imports \
		-fast \
		-release \
		-static \
		-largefile \
		-glib \
		-graphicssystem raster \
		-qt-zlib \
		-qt-libpng \
		-qt-libmng \
		-qt-libtiff \
		-qt-libjpeg \
		-svg \
		-script \
		-webkit \
		-gtkstyle \
		-xmlpatterns \
		-script \
		-scripttools \
		-openssl-linked \
		-nomake demos \
		-nomake docs \
		-nomake examples \
		-nomake tools \
		-nomake tests \
		-nomake translations \
		-no-qt3support \
		-no-pch \
		-no-icu \
		-no-phonon \
		-no-phonon-backend \
		-no-rpath \
		-no-separate-debug-info \
		-no-dbus \
		-no-opengl \
		-no-openvg && \
	NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) && \
	export MAKEFLAGS=-j${NPROC} && \
	export MAKE_COMMAND="make -j${NPROC}" && \
	make && \
	make install && \
	cd /tmp/wkhtmltopdf && \
	qmake && \
	make && \
	make install && \
	rm -rf /tmp/*

# remove qt build packages #
RUN apk del .deps \
	&& rm -rf /var/cache/apk/*


RUN apk add --no-cache bash
RUN echo 'alias appbox="yarn --cwd /AppBox/System/Supervisor"' >> ~/.bashrc

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

# Siteserver
WORKDIR /AppBox/System
RUN git clone https://github.com/AppBox-project/siteserver.git SiteServer
WORKDIR /AppBox/System/SiteServer
RUN yarn install
RUN yarn add typescript

# add `/app/node_modules/.bin` to $PATH
ENV PATH /AppBox/System/Client/node_modules/.bin:$PATH
ENV PATH /AppBox/System/Server/node_modules/.bin:$PATH
ENV PATH /AppBox/System/Engine/node_modules/.bin:$PATH
ENV PATH /AppBox/System/Supervisor/node_modules/.bin:$PATH
ENV PATH /AppBox/System/SiteServer/node_modules/.bin:$PATH

ENV PUBLICURL https://appbox.vicvancooten.nl
ENV DBURL '192.168.0.2:27017'
ENV TZ="Europe/Amsterdam"

# start app
EXPOSE 8600 8601
WORKDIR /AppBox/System/Supervisor

CMD [ "appbox", "start" ]
