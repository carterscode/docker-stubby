# Use Debian Bullseye Slim base image
FROM debian:bullseye-slim

# Set environment variable for the UnrealIRCd version
ENV UNREAL_VERSION=unrealircd-latest

# Update package manager and install necessary dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    wget \
    libssl-dev \
    pkg-config \
    gdb \
    libpcre2-dev \ 
    libargon2-dev \
    libsodium-dev \
    libc-ares-dev \
    libcurl4-openssl-dev \
    tcl

# Download and extract the latest stable version of UnrealIRCd
RUN wget -O unrealircd.tar.gz https://www.unrealircd.org/downloads/${UNREAL_VERSION}.tar.gz && \
    tar xvzf unrealircd.tar.gz && \
    rm unrealircd.tar.gz

# Find the extracted directory name dynamically (in case it changes in the future)
RUN cd $(find . -maxdepth 1 -type d -name "unrealircd-*") && \
    mv * /unrealircd && \
    cd / && \
    rm -rf $(find . -maxdepth 1 -type d -name "unrealircd-*")

# Set working directory to UnrealIRCd source directory
WORKDIR /unrealircd

# Configure and compile UnrealIRCd
RUN ./Config && \
    make && \
    make install

# Expose the IRC ports
EXPOSE 6667
EXPOSE 6697

# Copy the default configuration file to the container
COPY unrealircd.conf.default /home/user/unrealircd/conf/unrealircd.conf

# Set the user as 'ircd'
USER ircd

# Start UnrealIRCd
CMD ["/home/user/unrealircd/UnrealIRCd", "foreground"]
