# TAK Server with PostgreSQL Docker Container
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH
ENV POSTGRES_VERSION=14
ENV TAK_USER=tak
ENV TAK_DB=cot
ENV TAK_PASSWORD=tak123

# Install system dependencies
RUN apt-get update && apt-get install -y \
    openjdk-17-jdk \
    postgresql-14 \
    postgresql-14-postgis-3 \
    postgresql-contrib-14 \
    git \
    curl \
    wget \
    supervisor \
    sudo \
    lsof \
    && rm -rf /var/lib/apt/lists/*

# Create application directory
WORKDIR /opt/takserver

# Clone and build TAK Server (using stable 5.1 release)
RUN git clone https://github.com/TAK-Product-Center/Server.git tak-server && \
    cd tak-server && \
    git checkout 5.1-RELEASE-8

# Set Java options for Java 17 compatibility and UTF-8 encoding
ENV JDK_JAVA_OPTIONS="--add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.io=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED --add-opens=java.base/java.util.concurrent=ALL-UNNAMED --add-opens=java.rmi/sun.rmi.transport=ALL-UNNAMED --add-opens=java.base/sun.nio.ch=ALL-UNNAMED --add-opens=java.base/java.nio=ALL-UNNAMED --add-opens=java.base/sun.util.calendar=ALL-UNNAMED --add-opens=java.security.jgss/sun.security.krb5=ALL-UNNAMED --add-opens=java.base/java.lang.reflect=ALL-UNNAMED --add-opens=java.base/java.text=ALL-UNNAMED --add-opens=java.desktop/java.awt.font=ALL-UNNAMED -Dfile.encoding=UTF-8"

# Set locale for proper character encoding
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Build TAK Server with proper encoding
WORKDIR /opt/takserver/tak-server/src
RUN chmod +x gradlew && \
    JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF-8" ./gradlew clean bootWar bootJar shadowJar

# Setup PostgreSQL
RUN service postgresql start && \
    sudo -u postgres createuser -s $TAK_USER && \
    sudo -u postgres createdb -O $TAK_USER $TAK_DB && \
    sudo -u postgres psql -c "ALTER USER $TAK_USER PASSWORD '$TAK_PASSWORD';" && \
    sudo -u postgres psql -d $TAK_DB -c "CREATE EXTENSION postgis;" && \
    service postgresql stop

# Configure PostgreSQL to accept connections
RUN echo "host all all 0.0.0.0/0 md5" >> /etc/postgresql/$POSTGRES_VERSION/main/pg_hba.conf && \
    echo "listen_addresses='*'" >> /etc/postgresql/$POSTGRES_VERSION/main/postgresql.conf

# Create TAK Server working directory
WORKDIR /opt/takserver/tak-server/src/takserver-core

# Copy configuration files
COPY docker-entrypoint.sh /opt/takserver/
COPY init-database.sql /opt/takserver/
COPY supervisord.conf /etc/supervisor/conf.d/
COPY CoreConfig.xml /opt/takserver/tak-server/src/takserver-core/
COPY UserAuthenticationFile.xml /opt/takserver/tak-server/src/takserver-core/

# Create minimal certificate to satisfy JWK requirements (even though using HTTP)
RUN mkdir -p files/certs && \
    keytool -genkeypair -noprompt \
        -alias takserver \
        -dname "CN=takserver,O=TAK,C=US" \
        -keystore files/certs/takserver.jks \
        -keypass atakatak \
        -storepass atakatak \
        -keyalg RSA \
        -keysize 2048 \
        -validity 365

# Set permissions
RUN chmod +x /opt/takserver/docker-entrypoint.sh && \
    chown -R postgres:postgres /var/lib/postgresql && \
    chmod 600 CoreConfig.xml UserAuthenticationFile.xml

# Create logs directory
RUN mkdir -p logs

# Expose ports
EXPOSE 8443 8089 8087 5432

# Start services
CMD ["/opt/takserver/docker-entrypoint.sh"]