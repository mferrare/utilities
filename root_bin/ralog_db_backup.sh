#!/bin/bash
#
# Backs up RALog supabase database
#
# Exit immediately if
# - any command returns a non-zero error
# - any variable is unset
# - any command to a pipe fails
set -euo pipefail

DB_PASSWORD=`cat /root/bin/ralog.pass`
DB_HOST="aws-1-ap-southeast-2.pooler.supabase.com"

CONNECTION_STRING="postgresql://postgres.putuphnphwpdlwxpcehp:${DB_PASSWORD}@${DB_HOST}:5432/postgres"
BACKUP_PATH="/var/backups/ralog_db_backup.sql"

# Make sure the network is up. If this script is kicked off too soon on resume
# from a suspend it will run before network is up and could fail.
# Try to resolve the host and sleep
for i in {1..30}
do
	if getent hosts "$HOST" > /dev/null 2>&1
	then
		break
	fi
	sleep 2
done

# Will exit if this fails
getent hosts "$HOST" > /dev/null

# If we're here the network is up. Let's run the backup
pg_dump "$CONNECTION_STRING" -F c -B -v -f $BACKUP_PATH
