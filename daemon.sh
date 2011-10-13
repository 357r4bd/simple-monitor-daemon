#!/bin/sh

# !!! All values in ./config.sh are available here

PWD=`pwd`
SPOOLDIR=$PWD/rund # default, but set in config.sh
PID=rund.pid
VERBOSITY=1 # rund.sh reports it is running via STDOUT every $VERBOSITY seconds
DAEMONPIDFILE=$SPOOLDIR/$PID

# Do Not Modify Below This Line #
if [ ! -d $SPOOLDIR ]; then
  mkdir -p $SPOOLDIR 
fi

write_pid()
{ if [ -e $DAEMONPIDFILE ]; then
    echo pid exists..rund already running or the file is stale restarting 
    rm -rf $DAEMONPIDFILE
    echo waiting 5 seconds to restart
    sleep 5 
    echo OK ... starting $0
  fi
  echo $$ > $DAEMONPIDFILE
  echo $0 $@ >> $DAEMONPIDFILE
  echo `pwd` >> $DAEMONPIDFILE
}

handle_msg()
{ STATUS=$SPOOLDIR/$1
  echo detected incoming message, $STATUS
  echo `perl ${SCRIPTDIR}/query_msg.pl -F '##Message## %MESSAGE%' < $STATUS`
}

handler_dispatch()
{ case $1 in 
         msg) handle_msg $2;;
           *) echo Warning: \"$1\" is not a recognized message type;;
  esac;
}

# A manual override to shut down daemon - delete pid file!
ensure_pid()
{ if [ ! -e $DAEMONPIDFILE ]; then
    echo No PID file, shutting down daemon
    exit
  fi
}

write_pid;

# main loop
count=0
while [ 1 ]; do
  for FILExyz in `ls $SPOOLDIR`; do
    if [ $FILExyz != $PID ]; then 
      echo Event: $FILExyz detected
      # Perl one-line to parse file name
      status=`echo $FILExyz | perl -e 'print "$1\n" if(<STDIN>=~m/.([\w\d]*)$/);'`
      # Call dispatch function
      handler_dispatch $status $FILExyz
      # Upon return, delete the status file if it has not already been
      # dealt with by one of the handlers
      if [ -e $SPOOLDIR/$FILExyz ]; then
        rm -rf $SPOOLDIR/$FILExyz 
      fi
    fi
  done;
  ensure_pid
  count=$(($count+1))
  # output status every so often 
  if [ 0 -eq $(($count%$VERBOSITY)) ]; then
    echo [$count] ..o0O0o.zzZZzz.o0O0o.. 
  fi
  sleep 1;
done
