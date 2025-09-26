FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y \
    cowsay \
    fortune-mod \
    netcat \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY wisecow.sh .

RUN chmod +x wisecow.sh


EXPOSE 4499

CMD ["./wisecow.sh"]
