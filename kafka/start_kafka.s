# start_kafka.s
# for a Mac
# brew install kafka

log_file='kafka.log'

if [ -f $log_file ] ; then
  mv -f $log_file $log_file.bak
fi

kafka_start_loc=`which kafka-server-start`

if [ "x" == "x$kafka_start_loc" ] ; then
  echo
  echo "ERROR: kafka is not installed."
  echo "       do 'brew install kafka' on the Mac"
  echo
else

  zookeeper-server-start  ./config/zookeeper.properties & \
    kafka-server-start    ./config/kafka.properties

fi

