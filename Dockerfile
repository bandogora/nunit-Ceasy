FROM debian:bullseye-slim

LABEL org.opencontainers.image.title="Unit (C)"
LABEL org.opencontainers.image.description="Unofficial build of Unit for Docker."
LABEL org.opencontainers.image.url="https://github.com/bandogora/nunit-Ceasy"
LABEL org.opencontainers.image.source="https://github.com/bandogora/nunit-Ceasy"
LABEL org.opencontainers.image.documentation="https://unit.nginx.org/installation/#docker-images"

# Copy app source files
COPY --link ./src/* /usr/src/app/

# Add the default entrypoint (unsafe links)
ADD --link https://raw.githubusercontent.com/nginx/unit/master/pkg/docker/docker-entrypoint.sh /usr/local/bin/

# Add the default welcome page (unsafe links)
ADD --link https://raw.githubusercontent.com/nginx/unit/master/pkg/docker/welcome.html /usr/share/unit/welcome/welcome.html
ADD --link https://raw.githubusercontent.com/nginx/unit/master/pkg/docker/welcome.json /usr/share/unit/welcome/welcome.json

# Copy initial config
COPY ./config.json /docker-entrypoint.d/

# Make sure the entrypoint is executable
RUN ["chmod", "+x", "/usr/local/bin/docker-entrypoint.sh"]

RUN set -ex \
  && savedAptMark="$(apt-mark showmanual)" \
  && apt-get update \
  && apt-get install --no-install-recommends --no-install-suggests -y ca-certificates mercurial build-essential libssl-dev libpcre2-dev curl pkg-config \
  && mkdir -p /usr/lib/unit/modules /usr/lib/unit/debug-modules \
  && mkdir -p /usr/src/app \
  && cd /usr/src \
  && hg clone -u 1.31.0-1 https://hg.nginx.org/unit \
  && cd unit \
  && NCPU="$(getconf _NPROCESSORS_ONLN)" \
  && DEB_HOST_MULTIARCH="$(dpkg-architecture -q DEB_HOST_MULTIARCH)" \
  && export DEB_BUILD_MAINT_OPTIONS="hardening=+all,-pie" \
  && CC_OPT="$(DEB_CFLAGS_MAINT_APPEND="-Wp,-D_FORTIFY_SOURCE=2 -fPIC" dpkg-buildflags --get CFLAGS)" \
  && LD_OPT="$(DEB_LDFLAGS_MAINT_APPEND="-Wl,--as-needed -pie" dpkg-buildflags --get LDFLAGS)" \
  && CONFIGURE_ARGS_MODULES="--prefix=/usr \
              --statedir=/var/lib/unit \
              --control=unix:/var/run/control.unit.sock \
              --runstatedir=/var/run \
              --pid=/var/run/unit.pid \
              --logdir=/var/log \
              --log=/var/log/unit.log \
              --tmpdir=/var/tmp \
              --user=unit \
              --group=unit \
              --openssl \
              --libdir=/usr/lib/$DEB_HOST_MULTIARCH" \
  && CONFIGURE_ARGS="$CONFIGURE_ARGS_MODULES --njs" \
  && make -j $NCPU -C pkg/contrib .njs \
  && export PKG_CONFIG_PATH=$(pwd)/pkg/contrib/njs/build \
  && ./configure $CONFIGURE_ARGS --cc-opt="$CC_OPT" --ld-opt="$LD_OPT" --modulesdir=/usr/lib/unit/debug-modules --debug \
  && make -j $NCPU unitd \
  && install -pm755 build/sbin/unitd /usr/sbin/unitd-debug \
  && make clean \
  && ./configure $CONFIGURE_ARGS --cc-opt="$CC_OPT" --ld-opt="$LD_OPT" --modulesdir=/usr/lib/unit/modules \
  && make -j $NCPU unitd \
  && install -pm755 build/sbin/unitd /usr/sbin/unitd \
  && make clean \
  && /bin/true \
  && ./configure $CONFIGURE_ARGS_MODULES --cc-opt="$CC_OPT" --modulesdir=/usr/lib/unit/debug-modules --debug \
  && ./configure  \
  && make -j $NCPU version \
  && make clean \
  && ./configure $CONFIGURE_ARGS_MODULES --cc-opt="$CC_OPT" --modulesdir=/usr/lib/unit/modules \
  && ./configure  \
  && make -j $NCPU version \
  && make clean \
  && ./configure $CONFIGURE_ARGS --cc-opt="$CC_OPT" --ld-opt="$LD_OPT" --modulesdir=/usr/lib/unit/debug-modules --debug  \
  && make -j $NCPU libunit-install \
  && chmod +x ./build/lib/libunit.a \
  && mv ./build/lib/libunit.a ../app/libunit.a \
  && cd \
  && for f in /usr/sbin/unitd /usr/lib/unit/modules/*.unit.so; do \
      ldd $f | awk '/=>/{print $(NF-1)}' | while read n; do dpkg-query -S $n; done | sed 's/^\([^:]\+\):.*$/\1/' | sort | uniq >> /requirements.apt; \
     done \
  && apt-mark showmanual | xargs apt-mark auto > /dev/null \
  && { [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; } \
  && /bin/true \
  && mkdir -p /var/lib/unit/ \
  && mkdir -p /docker-entrypoint.d/ \
  && groupadd --gid 999 unit \
  && useradd \
       --uid 999 \
       --gid unit \
       --no-create-home \
       --home /nonexistent \
       --comment "unit user" \
       --shell /bin/false \
       unit \
  && apt-get update \
  && apt-get --no-install-recommends --no-install-suggests -y install curl $(cat /requirements.apt) \
  && ln -sf /dev/stdout /var/log/unit.log

# Compile and link C app against libunit.a
Run set -x \
  && export DEB_BUILD_OPTIONS="hardening=+all,-pie" \
  && CC_OPT="$(DEB_CFLAGS_APPEND="-D_FORTIFY_SOURCE=2 -fPIC" dpkg-buildflags --get CFLAGS)" \
  && LD_OPT="$(DEB_LDFLAGS_APPEND="-Wl,--as-needed -pie -L. -lc -l:libunit.a -lpthread" dpkg-buildflags --get LDFLAGS)" \
  && cd /usr/src/app \
  && gcc $CC_OPT hello.c -o hello $LD_OPT \
  && chmod +x ./hello \
  && mv ./hello /srv/hello

# Cleanup
RUN set -x \
  && apt-get purge -y --auto-remove build-essential \
  && rm -rf /usr/src/ \
  && rm -rf /var/lib/apt/lists/* \
  && rm -f /requirements.apt

STOPSIGNAL SIGTERM

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
EXPOSE 80
CMD ["unitd", "--no-daemon", "--control", "unix:/var/run/control.unit.sock"]
