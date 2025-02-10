#!/bin/bash
set -euxo pipefail
POSTGRESQL_MAJOR_VERSION=17
PLV8_VERSION=3.2.3
# calling syntax: install_pg_extensions.sh [extension1] [extension2] ...

# install extensions
EXTENSIONS="$@"
# cycle through extensions list
for EXTENSION in ${EXTENSIONS}; do    
    # special case: timescaledb
    if [ "$EXTENSION" == "plv8" ]; then
        # dependencies
        buildDependencies="build-essential \
            ca-certificates \
            curl \
            git-core \
            gpp \
            cpp \
                gnupg dirmngr \
            pkg-config \
            apt-transport-https \
            cmake \
            libc++-dev \
            libncurses5 \
            libc++abi-dev \
                libstdc++-10-dev \
                wget \
                zlib1g-dev \
                postgresql-server-dev-${POSTGRESQL_MAJOR_VERSION} \
                libtinfo5" \
            runtimeDependencies="libc++1" \
            && apt-get update && apt-get install -y --no-install-recommends ${buildDependencies} ${runtimeDependencies}
    
        mkdir -p /tmp/build \
          && curl -o /tmp/build/v3.2.3.tar.gz -SL "https://github.com/plv8/plv8/archive/refs/tags/v3.2.3.tar.gz" \
          && cd /tmp/build \
          && tar -xzf /tmp/build/v3.2.3.tar.gz -C /tmp/build/
        cd /tmp/build/plv8-3.2.3/deps \
          && git clone https://github.com/bnoordhuis/v8-cmake.git \
          && cd /tmp/build/plv8-3.2.3 \
          && git init \
          && make \
          && make install \
          && strip /usr/lib/postgresql/${PG_VERSION}/lib/plv8-3.2.3.so
        apt-get clean \
          && apt-get remove -y ${buildDependencies} \
          && apt-get autoremove -y \
          && rm -rf /tmp/build /var/lib/apt/lists/*
        continue
    fi

    # is it an extension found in apt?
    if apt-cache show "postgresql-${PG_MAJOR}-${EXTENSION}" &> /dev/null; then
        # install the extension
        apt-get install -y "postgresql-${PG_MAJOR}-${EXTENSION}"
        continue
    fi

    # extension not found/supported
    echo "Extension '${EXTENSION}' not found/supported"
    exit 1
done
