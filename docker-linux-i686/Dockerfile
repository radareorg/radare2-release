FROM i386/debian

RUN apt update
RUN apt install -y gcc make patch git sudo
COPY build-r2.sh /
RUN chmod +x /build-r2.sh
ENTRYPOINT /build-r2.sh
