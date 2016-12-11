FROM debian

RUN apt update
RUN apt install -y gcc make patch git sudo
COPY ../docker/build-r2.sh /
RUN chmod +x /build-r2.sh
ENTRYPOINT setarch i686 /build-r2.sh

