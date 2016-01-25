
docker run --rm -it -v $PWD:/app -w /app iron/ruby-bundle bundle update
docker run --rm -it -v $PWD:/app -w /app iron/ruby-bundle bundle install --standalone --clean
