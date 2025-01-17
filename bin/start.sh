#!/bin/sh
QUICK="no"
while [ "$#" -gt 0 ]; do

	if [ "$1" = "-q" ]; then
		QUICK="yes"
	else 
		PARAMS="$PARAMS $1"
	fi

	shift

done

# resolve links - so that script can be called from any dir
PRG="$0"

while [ -h "$PRG" ]; do
  ls=`ls -ld "$PRG"`
  link=`expr "$ls" : '.*-> \(.*\)$'`
  if expr "$link" : '/.*' > /dev/null; then
    PRG="$link"
  else
    PRG=`dirname "$PRG"`/"$link"
  fi
done

# Get standard environment variables
PRGDIR=`pwd`/`dirname "$PRG"`


. $PRGDIR/config.sh

if [ -z "$JREBEL_HOME" ] ; then
    echo "you do not have JREBEL installed.  If you want to use JREBEL install it and define JREBEL_HOME.  It can be defined in the config.sh file in your profile"
else
  JREBEL_OPTS="-noverify -javaagent:$JREBEL_HOME/jrebel.jar"
fi

export MAVEN_OPTS="$OVERRIDES $MEMORY -Dfile.encoding=UTF8 "

cd $PRGDIR/..

if [ "$QUICK" = "no" ]; then
    echo "Compiling geonetwork"
	mvn install -P-all -DskipTests $PARAMS
	if [ ! $? -eq 0 ]; then
		echo "[FAILURE] [deploy] Failed to build geonetwork correctly"
		exit -1
	fi
fi

export MAVEN_OPTS="$JREBEL_OPTS $DEBUG $OVERRIDES $MEMORY -Dgeonetwork.dir=$DATA_DIR $LOGGING -Dfile.encoding=UTF8 "
cd $WEB_DIR
echo "Running geonetwork webserver"
mvn jetty:run -o -Penv-dev $PARAMS
