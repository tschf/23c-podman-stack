#!/bin/bash
# This script is being used to decide when to stop watching the log file for the
# initial ORDS (and APEX) installation.
set -e

# The ords process doesn't start until ORDS DB object have been installed. We can
# use that to know once everything has completed.
while ! pgrep ords > /dev/null
do
  sleep 1s
done

# After ords startup it has to install some things - which doesn't take look. So
# give half a minute before killing the tail process
sleep 30s

tailPid=$(pgrep tail)
kill -9 "$tailPid"