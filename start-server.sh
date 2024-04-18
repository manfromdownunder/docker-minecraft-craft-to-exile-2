#!/bin/bash

read_rcon_password(){
  RCON_PASSWORD=$(grep 'rcon.password=' /minecraft/server/server.properties | cut -d'=' -f2)
}

send_rcon(){
  mcrcon -c -H localhost -P 25575 -p "$RCON_PASSWORD" "$@"
}

start_server(){
  echo "Starting Minecraft server."
  java -Xmx${JAVA_MEMORY_MAX} \
       -Xms${JAVA_MEMORY_MIN} \
       -XX:+UseG1GC \
       -XX:+ParallelRefProcEnabled \
       -XX:MaxGCPauseMillis=200 \
       -XX:+UnlockExperimentalVMOptions \
       -XX:+DisableExplicitGC \
       -XX:+AlwaysPreTouch \
       -XX:G1NewSizePercent=20 \
       -XX:G1ReservePercent=20 \
       -XX:G1HeapRegionSize=32M \
       -jar /minecraft/server/forge-${MINECRAFT_VERSION}-${FORGE_VERSION}.jar nogui &
  MINECRAFT_PID=$!
}


send_countdown(){
  for i in 5 4 3 2; do
    send_rcon "say Server is $1 in $i minutes!"
    sleep 60
  done
  send_rcon "say Server is $1 in 60 seconds."
  sleep 30
  send_rcon "say Server is $1 in 30 seconds. Please log out now!"
  sleep 25
  send_rcon "say Server is $1 in 5 seconds. Please log out now!"
  sleep 5
  send_rcon "say Server is $1 now!"
}

stop_server(){
  echo "Stopping Minecraft server."
  send_countdown "shutting down"
  if [ ! -z "$MINECRAFT_PID" ]; then
    kill -SIGTERM "$MINECRAFT_PID"
    wait "$MINECRAFT_PID"
  fi
}

restart_server(){
  echo "Restarting Minecraft server."
  send_countdown "restarting"
  if [ ! -z "$MINECRAFT_PID" ]; then
    kill -SIGTERM "$MINECRAFT_PID"
    wait "$MINECRAFT_PID"
  fi
  sleep 5
  start_server
}

trap stop_server SIGTERM SIGINT

echo "Starting server"
read_rcon_password
rm -f autostart.stamp
start_server

while true; do
  sleep 10
  
  if [ -e autostop.stamp ]; then
    echo "autostop.stamp found. Stopping server."
    rm -f autostop.stamp
    stop_server
    break
  fi
  
  if [ -e autostart.stamp ]; then
    echo "autostart.stamp found. Restarting server."
    rm -f autostart.stamp
    restart_server
    echo "Server process restarted."
  fi
done

wait $!