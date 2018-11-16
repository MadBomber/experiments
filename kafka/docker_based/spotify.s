
export ADVERTISED_HOST=172.17.0.1
export ADVERTISED_PORT=9092

docker run -p 2181:2181 -p 9092:9092 spotify/kafka
