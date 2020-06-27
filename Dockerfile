# Build image
FROM golang:1.14 AS builder

#ENV GOPROXY="http://mirrors.aliyun.com/goproxy/"
ADD . /ipmi_exporter/
RUN cd /ipmi_exporter && go build -o ipmi_exporter

# Container image
FROM debian:buster-slim

WORKDIR /

#RUN echo "deb http://mirrors.aliyun.com/debian buster main" > /etc/apt/sources.list

RUN apt-get update \
    && apt-get install freeipmi-tools -y --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /ipmi_exporter/ipmi_exporter /bin/ipmi_exporter
COPY ./ipmi_remote.yml /config.yml

EXPOSE 9290
ENTRYPOINT ["/bin/ipmi_exporter"]
CMD ["--config.file", "/config.yml"]
