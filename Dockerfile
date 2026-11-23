FROM judge0/compilers:1.4.0 AS builder

ENV PATH="/usr/local/ruby-2.7.0/bin:/opt/.gem/bin:$PATH" \
    GEM_HOME="/opt/.gem/"

RUN sed -i 's|http://deb.debian.org/debian|http://archive.debian.org/debian|g; s|http://security.debian.org/debian-security|http://archive.debian.org/debian-security|g; /buster-updates/d' /etc/apt/sources.list && \
    apt-get -o Acquire::Check-Valid-Until=false update && \
    apt-get install -y --no-install-recommends \
      cron \
      libpq5 \
      libpq-dev \
      sudo && \
    echo "gem: --no-document" > /root/.gemrc && \
    gem install bundler:2.1.4 && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /api

COPY Gemfile* ./
RUN RAILS_ENV=production bundle install --without development test && \
    apt-mark manual libpq5 && \
    apt-get purge -y --auto-remove libpq-dev && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/* /opt/.gem/cache/* /tmp/* /var/tmp/* && \
    rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/info/* \
           /usr/local/*/share/doc /usr/local/*/share/man \
           /usr/local/openjdk13/jmods \
           /usr/local/go-1.13.5/test /usr/local/go-1.13.5/doc /usr/local/go-1.13.5/misc /usr/local/go-1.13.5/api \
           /usr/local/mono-6.6.0.161/lib/monodoc \
           /usr/local/mono-6.6.0.161/lib/*.a \
           /usr/local/python-*/lib/python*/test \
           /usr/local/ruby-2.7.0/lib/libruby-static.a \
           /usr/local/swift-5.2.3/bin/lldb* \
           /usr/local/swift-5.2.3/bin/sourcekit-lsp \
           /usr/local/swift-5.2.3/bin/clangd \
           /usr/local/swift-5.2.3/bin/swift-api-digester \
           /usr/local/swift-5.2.3/bin/swift-package \
           /usr/local/swift-5.2.3/bin/swift-build \
           /usr/local/swift-5.2.3/bin/swift-test \
           /usr/local/swift-5.2.3/bin/swift-run \
           /usr/local/swift-5.2.3/bin/llvm-cov \
           /usr/local/swift-5.2.3/lib/liblldb* \
           /usr/local/rust-1.40.0/bin/rustdoc \
           /usr/local/ghc-8.8.1 \
           /usr/local/octave-5.1.0 \
           /usr/local/ocaml-4.09.0 \
           /usr/local/dotnet-sdk \
           /usr/local/fpc-3.0.4 \
           /usr/local/d-2.089.1 \
           /usr/local/gcc-9.2.0 \
           /usr/local/gcc-8.3.0 \
           /usr/local/gcc-7.4.0 \
           /usr/local/erlang-22.2 \
           /usr/local/python-2.7.17 \
           /usr/local/r-4.0.0 \
           /usr/local/fbc-1.07.1 \
           /usr/local/sbcl-2.0.0 \
           /usr/local/scala-2.13.2 \
           /usr/local/gprolog-1.4.5 \
           /usr/local/elixir-1.9.4 \
           /usr/local/clojure-1.10.1 \
           /usr/local/gnucobol-2.2 \
           /usr/local/nasm-2.14.02 \
           /usr/local/lua-5.3.5 && \
    find /usr/local/python-* -type f -name "libpython*.a" -delete && \
    find /usr/local -type d -name "__pycache__" -exec rm -rf {} + && \
    find /usr/local -path "/usr/local/go-*" -prune -o -type f \( -name "*.so*" -o -perm -111 \) -exec strip --strip-unneeded {} + 2>/dev/null || true

COPY cron /etc/cron.d
RUN cat /etc/cron.d/* | crontab -

COPY . .

RUN useradd -u 1000 -m -r judge0 && \
    echo "judge0 ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers && \
    chmod 0440 /etc/sudoers && \
    chown judge0: /api/tmp/


FROM scratch AS production

COPY --from=builder / /

RUN chmod 4755 /usr/local/bin/isolate /usr/bin/sudo && \
    chmod 1777 /tmp /var/tmp

ENV LANG="en_US.UTF-8" \
    LANGUAGE="en_US:en" \
    LC_ALL="en_US.UTF-8" \
    BOX_ROOT="/var/local/lib/isolate" \
    PATH="/usr/local/ruby-2.7.0/bin:/opt/.gem/bin:$PATH" \
    GEM_HOME="/opt/.gem/"

ENV JUDGE0_HOMEPAGE="https://judge0.com"
LABEL homepage=$JUDGE0_HOMEPAGE

ENV JUDGE0_SOURCE_CODE="https://github.com/judge0/judge0"
LABEL source_code=$JUDGE0_SOURCE_CODE

ENV JUDGE0_MAINTAINER="Herman Zvonimir Došilović <hermanz.dosilovic@gmail.com>"
LABEL maintainer=$JUDGE0_MAINTAINER

ENV JUDGE0_VERSION="1.13.1"
LABEL version=$JUDGE0_VERSION

EXPOSE 2358
WORKDIR /api

ENTRYPOINT ["/api/docker-entrypoint.sh"]
CMD ["/api/scripts/server"]

USER judge0


FROM production AS development

USER root
RUN npm install -g --unsafe-perm aglio@2.3.0 && \
    rm -rf /root/.npm /tmp/*
USER judge0

CMD ["sleep", "infinity"]
