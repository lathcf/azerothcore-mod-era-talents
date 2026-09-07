# Throwaway build/run image for the era-talents client patch: StormLib + mpqpack/mpqread + python3/PyYAML
# + git/7z, so a host with only Docker can produce the merged patch-V.mpq (used by build-client-patch.sh
# when the native toolchain is absent). Build context = this client-patch/ directory.
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
      git ca-certificates cmake make gcc g++ zlib1g-dev libbz2-dev python3 python3-yaml p7zip-full \
    && rm -rf /var/lib/apt/lists/*
# build-mpqpack.sh resolves the repo root as its parent dir, so mirror the layout under /opt/mpq.
COPY mpqpack.c mpqread.c build-mpqpack.sh /opt/mpq/client-patch/
RUN bash /opt/mpq/client-patch/build-mpqpack.sh && rm -rf /opt/mpq/deps/StormLib/build/CMakeFiles
ENV MPQPACK=/opt/mpq/client-patch/mpqpack MPQREAD=/opt/mpq/client-patch/mpqread HOME=/tmp
WORKDIR /work
