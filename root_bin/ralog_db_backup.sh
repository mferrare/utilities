#!/bin/bash
#
# Backs up RALog supabase database
#
# Exit immediately if
# - any command returns a non-zero error
# - any variable is unset
# - any command to a pipe fails
set -euo pipefail

# Environment variables and password file live in same 
# location as the executable script
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# Get environment variables and export
ENVFILE="$SCRIPT_DIR/borg_backup.env"
if [[ -r "$ENVFILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENVFILE"
fi

# Fail fast if required vars aren't set by the env file
: "${DB_HOST:?DB_HOST not set}"
: "${DB_PORT:?DB_PORT not set}"
: "${DB_NAME:?DB_NAME not set}"
: "${DB_USER:?DB_USER not set}"
: "${DB_PASS_FILE:?DB_PASS_FILE not set}"
: "${BACKUP_PATH:?BACKUP_PATH not set}"
: "${CONNECTION_STRING:?CONNECTION_STRING not set}"

# Get the password
DB_PASSWORD=$(grep -m1 -E '^[[:space:]]*[^#[:space:]]' "${SCRIPT_DIR}/${DB_PASS_FILE}")

# Make a .pgpass file. We make this each time in case any of the
# db parameters change
PGPASSFILE="${SCRIPT_DIR}/.pgpass"
umask 077
printf '%s:%s:%s:%s:%s\n' "$DB_HOST" "$DB_PORT" "$DB_NAME" "$DB_USER" "$DB_PASSWORD" > "$PGPASSFILE"
chmod 600 "$PGPASSFILE"
# Need to export this so pg_dump sees it.
export PGPASSFILE

# Remove passfile on exit.
trap 'rm -f "$PGPASSFILE"' EXIT


# Make sure the network is up. If this script is kicked off too soon on resume
# from a suspend it will run before network is up and could fail.
# Try to resolve the host and sleep
for i in {1..30}
do
	if getent hosts "$DB_HOST" > /dev/null 2>&1
	then
		break
	fi
	sleep 2
done

# Will exit if this fails
getent hosts "$DB_HOST" > /dev/null

# If we're here the network is up. Let's run the backup
pg_dump "$CONNECTION_STRING" -F c -B -v -f "$BACKUP_PATH"
