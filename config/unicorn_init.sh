#!/bin/sh
set -e

TIMEOUT=${TIMEOUT-60}
APP_NAME=cookbook
APP_ROOT=/home/pico/apps/cookbook/current
PID=$APP_ROOT/tmp/pids/unicorn.pid
CMD="cd $APP_ROOT && bin/unicorn -c $APP_ROOT/config/unicorn.rb -E production -D"
USER=pico
action="$1"
set -u

old_pid="$PID.oldbin"

cd $APP_ROOT || exit 1

sig () {
  test -s "$PID" && kill -$1 `cat $PID`
}

oldsig () {
  test -s $old_pid && kill -$1 `cat $old_pid`
}

workersig () {
        workerpid="/tmp/unicorn.$APP_NAME.$2.pid"
  test -s "$workerpid" && kill -$1 `cat $workerpid`
}

case $action in
start)
  sig 0 && echo >&2 "Already running" && exit 0
  su - $USER -c "$CMD"
  ;;
stop)
  sig QUIT && exit 0
  echo >&2 "Not running"
  ;;
force-stop)
  sig TERM && exit 0
  echo >&2 "Not running"
  ;;
restart|reload)
  sig HUP && echo reloaded OK && exit 0
  echo >&2 "Couldn't reload, starting '$CMD' instead"
  su - $USER -c "$CMD"
  ;;
upgrade)
  if sig USR2 && sleep 20 && sig 0 && oldsig QUIT
  then
    n=$TIMEOUT
    while test -s $old_pid && test $n -ge 0
    do
      printf '.' && sleep 1 && n=$(( $n - 1 ))
    done
    echo

    if test $n -lt 0 && test -s $old_pid
    then
      echo >&2 "$old_pid still exists after $TIMEOUT seconds"
      exit 1
    fi
    exit 0
  fi
  echo >&2 "Couldn't upgrade, starting '$CMD' instead"
  su - $USER -c "$CMD"
  ;;
kill_worker)
  workersig QUIT $2 && exit 0
  echo >&2 "Worker not running"
  ;;

reopen-logs)
  sig USR1
  ;;
*)
  echo >&2 "Usage: $0 <start|stop|restart|upgrade|force-stop|reopen-logs>"
  exit 1
  ;;
esac
