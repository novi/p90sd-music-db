FROM swift:5.10 AS builder

COPY . /root/app_repo
RUN cd /root/app_repo && \
    swift build -c release

FROM swift:5.10-slim

COPY --from=builder /root/app_repo/.build/release/p90sd-music-db /root/

CMD ["/root/p90sd-music-db"]
