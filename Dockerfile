FROM cm2network/steamcmd:latest
EXPOSE 8211

WORKDIR /home/steam/steamcmd/

RUN /home/steam/steamcmd/steamcmd.sh +login anonymous +app\_update 2394010 validate +quit

CMD /home/steam/Steam/steamapps/common/PalServer/PalServer.sh
