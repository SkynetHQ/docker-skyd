#!/bin/sh

# This adjusts the logrotate configuration to the current value of SIA_DATA_DIR.
sed -i "s#/sia-data#$SIA_DATA_DIR#gi" /etc/logrotate.d/sia

# Launch cron because it might not be running.
cron 1>/var/log/cron_sia.log 2>&1

# Use the `cat` utility in order assign a multi-line string to a variable.
SIAD_CMD=$(cat <<-END
siad \
  --disable-api-security \
  --modules $SIA_MODULES \
  --sia-directory $SIA_DATA_DIR \
  --api-addr :9980
END
)

# Get wanted UID and GID of host user (not docker container user) from mounted
# Sia data dir
USER_ID=$(stat -c "%u" "$SIA_DATA_DIR")
GROUP_ID=$(stat -c "%g" "$SIA_DATA_DIR")

# Check if we want to run Sia as non-root user
if [ "$(uname -m)" = "x86_64" ] && [ "$USER_ID" != "0" ]; then
  # Used username and groupname (inside docker container)
  SIA_USER=user
  SIA_GROUP="$SIA_USER"

  # Create group if not exists
  cat /etc/group | grep "^$SIA_GROUP:" > /dev/null || addgroup --gid="$GROUP_ID" "$SIA_GROUP"

  # Set wanted group GID (in case user existed and wanted GID has changed)
  groupmod -g "$GROUP_ID" "$SIA_GROUP"

  # Create user if not exists
  cat /etc/passwd | grep "^$SIA_USER:" > /dev/null || adduser \
    --disabled-password \
    --gecos "" \
    --ingroup "$SIA_GROUP" \
    --uid "$USER_ID" \
    "$SIA_USER"

  # Set wanted user UID (in case user existed and wanted UID has changed)
  usermod -u "$USER_ID" "$SIA_USER"

  # Change sia-data ownership recursively
  chown -R "$USER_ID:$GROUP_ID" "$SIA_DATA_DIR"

  # Run as given user

  # We are using `exec` to start `siad` in order to ensure that it will be run as
  # PID 1. We need that in order to have `siad` receive OS signals (e.g. SIGTERM)
  # on container shutdown, so it can exit gracefully and no data corruption can
  # occur.
  
  # We are using `su-exec` to start `siad` in order to change a user who
  # runs `siad` process (if we do not want to run as root).
  echo "Running Sia with permissions of a local user: $USER_ID:$GROUP_ID"
  exec "$SU_EXEC" "$USER_ID:$GROUP_ID" $SIAD_CMD "$@"
else
  # Change sia-data ownership recursively back to root
  chown -R root:root "$SIA_DATA_DIR"

  # Run as root

  # We are using `exec` to start `siad` in order to ensure that it will be run as
  # PID 1. We need that in order to have `siad` receive OS signals (e.g. SIGTERM)
  # on container shutdown, so it can exit gracefully and no data corruption can
  # occur.
  echo "Running Sia as root"
  exec $SIAD_CMD "$@"
fi