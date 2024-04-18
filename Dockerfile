# Use a specific Debian base image for reproducibility
FROM debian:bullseye-slim

# Set build-time variables
ARG JAVA_VERSION="temurin-18-jdk"

# Set default environment variables including EULA_ACCEPT
ENV EULA_ACCEPT="true" \
    MINECRAFT_VERSION="1.19" \
    SERVER_PORT="25565" \
    MODPACK_URL="https://www.curseforge.com/minecraft/modpacks/craft-to-exile-2" \
    JAVA_MEMORY_MAX="10000m" \
    JAVA_MEMORY_MIN="8000m" \
    JAVA_PERM_SIZE="256m" \
    FORGE_VERSION="" \
    RCON_ENABLED="true" \
    RCON_PASSWORD="yourpassword" \
    RCON_PORT="25575" \
    DIFFICULTY="normal" \
    GAMEMODE="survival" \
    HARDCORE="false" \
    LEVEL_NAME="world" \
    LEVEL_SEED="manfromdowunder" \
    MAX_BUILD_HEIGHT="256" \
    MAX_PLAYERS="5" \
    MOTD="Craft to Exile 2 Server" \
    PLAYER_IDLE_TIMEOUT="0" \
    PREVENT_PROXY_CONNECTIONS="false" \
    PVP="true" \
    SNOOPER_ENABLED="true" \
    VIEW_DISTANCE="7" \
    ALLOW_FLIGHT="true" \
    RESTART_INTERVAL="0 */6 * * *" \
    ALLOW_NETHER="true"

# Create a directory for Minecraft
WORKDIR /minecraft/server
WORKDIR /minecraft

# Install initial dependencies and tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends cron screen software-properties-common build-essential make wget git curl unzip tar nano logrotate gnupg2 apt-transport-https && \
    mkdir -p /etc/apt/keyrings && \
    wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | tee /etc/apt/keyrings/adoptium.asc && \
    echo "deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print $2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends $JAVA_VERSION && \
    apt-get install -y libxfixes3 libxdamage1 libxcomposite1 libatk1.0-0 libnss3 libxss1 libasound2 libpangocairo-1.0-0 libcups2 libxrandr2 libgbm1 libatk-bridge2.0-0 libxkbcommon0 && \
    curl -sL https://deb.nodesource.com/setup_14.x | bash - && \
    apt-get install -y nodejs && \
    git clone https://github.com/manfromdownunder/docker-minecraft-steampunk-lps.git && \
    cp docker-minecraft-steampunk-lps/downloadmods.sh ./downloadmods.sh && \
    cp docker-minecraft-steampunk-lps/modslist.txt ./modslist.txt && \
    cp docker-minecraft-steampunk-lps/downloadFromCurseForge.js ./downloadFromCurseForge.js && \
    cp docker-minecraft-steampunk-lps/start-server.sh /minecraft/server/start-server.sh && \
    cp docker-minecraft-steampunk-lps/restart-server.sh /minecraft/server/restart-server.sh && \
    chmod +x /minecraft/server/start-server.sh && \
    chmod +x ./downloadmods.sh && \
    chmod +x /minecraft/server/restart-server.sh && \
    echo "${RESTART_INTERVAL} /minecraft/server/restart-server.sh >> /minecraft/server/logs/restart-server.log 2>&1" > /etc/cron.d/restart-server && \
    chmod 0644 /etc/cron.d/restart-server && \
    crontab /etc/cron.d/restart-server && \
    touch /var/log/restart-server.log && \
    wget https://github.com/Tiiffi/mcrcon/archive/v0.0.5.tar.gz && \
    tar -xzvf v0.0.5.tar.gz && \
    cd mcrcon-0.0.5 && \
    gcc -o mcrcon mcrcon.c && \
    mv mcrcon /usr/local/bin && \
    cd .. && \
    ./downloadmods.sh modslist.txt && \
    chmod +x /minecraft/server/start.sh

# Change to the server directory inside the main Minecraft directory
WORKDIR /minecraft/server

# Generate eula.txt and server.properties with explicit paths
RUN echo "eula=${EULA_ACCEPT}" > /minecraft/server/eula.txt && \
    { \
        echo "enable-rcon=${RCON_ENABLED}"; \
        echo "rcon.password=${RCON_PASSWORD}"; \
        echo "rcon.port=${RCON_PORT}"; \
        echo "difficulty=${DIFFICULTY}"; \
        echo "gamemode=${GAMEMODE}"; \
        echo "hardcore=${HARDCORE}"; \
        echo "level-name=${LEVEL_NAME}"; \
        echo "level-seed=${LEVEL_SEED}"; \
        echo "max-build-height=${MAX_BUILD_HEIGHT}"; \
        echo "max-players=${MAX_PLAYERS}"; \
        echo "motd=${MOTD}"; \
        echo "player-idle-timeout=${PLAYER_IDLE_TIMEOUT}"; \
        echo "prevent-proxy-connections=${PREVENT_PROXY_CONNECTIONS}"; \
        echo "pvp=${PVP}"; \
        echo "snooper-enabled=${SNOOPER_ENABLED}"; \
        echo "view-distance=${VIEW_DISTANCE}"; \
        echo "allow-flight=${ALLOW_FLIGHT}"; \
        echo "allow-nether=${ALLOW_NETHER}"; \
    } > /minecraft/server/server.properties

# Expose the Minecraft server port and RCON port
EXPOSE $SERVER_PORT $RCON_PORT

# Start the Minecraft server startup script
CMD ["/minecraft/server/start.sh"]