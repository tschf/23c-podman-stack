#!/bin/bash
set -e

# The ORDS container that installs APEX spools to the file:
# /tmp/install_container.log
log_file="/tmp/install_container.log"

# Use tail with the -n+ option - which means read FROM the specified line.
fromLine="1"

# Keep looping until we break manually. We drive this when there is no more content
# feeding into the specified log file.

# Initial sleep to give the log a chance to start populating
sleep 30s

while true
do
  # Get the lines into a variable
  iterLines=$(tail -n+$fromLine "$log_file")

  # We need to keep track of where to read the log from. So we need to get the
  # number of lines from the command
  numLinesPrinted=$(echo "$iterLines" | wc -l)

  # We keep track of where the next line to start from, is. Eventually we get a line
  # beyond what is in the file which causes us to get no content back
  fromLine=$((fromLine+numLinesPrinted))

  # The assignment operator returned a line even if no new lines were read so we
  # need to strip the new line character from the return value
  numBytesPrinted=$(echo "$iterLines" | tr -d '\n' | wc -c)

  # If 0 bytes were returned from the tail command it means no new content came
  # through and we should have finished processing the log file
  [[ "$numBytesPrinted" != "0" ]] || break

  # Sleep to give log a chance to expand. During tested I found the biggest period
  # was recompiling the APEX schema, which was around 65 secs. Setting to 80 to
  # allow  a bit of buffer.
  sleep 80s
done

# Once no more bytes were read within our timeout period, we kill the process
tailPid=$(pgrep tail)
kill -9 "$tailPid"