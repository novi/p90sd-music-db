FROM swift:4.1

COPY . /root/app_repo
RUN cd /root/app_repo && \
    swift build -c release && \
    mkdir -p /root/bin/release && \
    cp -R .build/release/* /root/bin/release && \
    rm -rf /root/app_repo

WORKDIR /root/bin/release


CMD ["/root/bin/release/p90sd-music-db"]