# Minecraft Craft to Exile 2

This is a docker image for [Craft to Exile 2](https://www.curseforge.com/minecraft/modpacks/craft-to-exile-2)

## Supported Architectures

Simply pulling `ghcr.io/manfromdownunder/docker-minecraft-craft-to-exile-2:latest` should retrieve the correct image for your arch, but you can also pull specific arch images via tags.

The architectures supported by this image are:

| Architecture | Available | Tag |
| :----: | :----: | ---- |
| amd64 | ✅ | docker-minecraft-craft-to-exile-2:latest |

## Hardware requirements
For 5-10 Players:
- Minimum 10GB RAM
- Minimum 4 cores @ 2.4Ghz

## Usage
You must install docker and docker-compose first and confirm it is working. Then follow the steps below to fire up your server. ** Don't forget to change passwords in the docker-compose.yml.  

1. Create the docker-compose.yml
```sudo nano docker-compose.yml```

2. Copy paste the example docker compose below into the docker-compose.yml then save
```Ctrl + O to write the file, then Ctrl + X to close the file```

3. Start the container
```docker-compose -f docker-compose.yml -d```

4. The server can take ~5 minutes to start so be patient

## docker-compose

```yaml
---
services:
  rad2_server:
    image: manfromdownunder/docker-minecraft-craft-to-exile-2:latest
    # command: tail -f /dev/null # debug the container
    container_name: docker-minecraft-craft-to-exile-2
    ports:
      - "25565:25565"
      - "25575:25575"
    environment:
      EULA_ACCEPT: "true"
      MINECRAFT_VERSION: "1.16.5"
      SERVER_PORT: "25565"
      MODPACK_URL: "https://www.curseforge.com/minecraft/modpacks/craft-to-exile-2"
      JAVA_MEMORY_MAX: "10000m"
      JAVA_MEMORY_MIN: "8000m"
      JAVA_PERM_SIZE: "256m"
      FORGE_VERSION: "36.2.39"
      RCON_ENABLED: "true"
      RCON_PASSWORD: "yourpassword"
      RCON_PORT: "25575"
      DIFFICULTY: "normal"
      GAMEMODE: "survival"
      HARDCORE: "false"
      LEVEL_NAME: "world"
      LEVEL_SEED: "manfromdowunder"
      MAX_BUILD_HEIGHT: "256"
      MAX_PLAYERS: "5"
      MOTD: "Craft to Exile 2 Server"
      PLAYER_IDLE_TIMEOUT: "0"
      PREVENT_PROXY_CONNECTIONS: "false"
      PVP: "true"
      SNOOPER_ENABLED: "true"
      VIEW_DISTANCE: "7"
      ALLOW_FLIGHT: "true"
      ALLOW_NETHER: "true"
      RESTART_INTERVAL: "0 */4 * * *"
    volumes:
      - ./world:/minecraft/server/world
      - ./world:/minecraft/server/backups
      - ./logs:/minecraft/server/logs
      - ./control/ops.json:/minecraft/server/ops.json
#      - ./control/banned-ips.json:/minecraft/server/banned-ips.json
#      - ./control/banned-players.json:/minecraft/server/banned-players.json
#      - ./control/whitelist.json:/minecraft/server/whitelist.json
#      - ./start-server.sh:/minecraft/server/start-server.sh # uncomment this line to customize the startup script
```

## minecraft docker commands
Manually initiate a server restart
```docker exec -it minecraft-craft-to-exile-2 touch /minecraft/server/autostart.stamp```

Manually initiate a server shutdown
```docker exec -it minecraft-craft-to-exile-2 touch /minecraft/server/autostop.stamp```



## Versions

* **1.0.0:** - Initial release.
