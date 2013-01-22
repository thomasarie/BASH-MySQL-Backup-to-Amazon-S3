#!/bin/bash

# MySQL info you want to back up
DB_NAME='database_name'
DB_USER='database_user' # Make sure have privileges with lock tables
DB_PSWD='database_password'
DB_HOST='localhost'

# S3 bucket where the file will be stored, please use trailing slash
S3_BUCKET='s3://bucket_name/path/to/folder/'

# Temporary local place for backup
DUMP_LOC='/path/to/dump/'
DUMP_LOG='/path/to/log/'

# How long the backup in local will be kept
DAYS_OLD="10"

# Logging 
START_TIME="$(date +"%s")"
DATE_BAK="$(date +"%Y-%m-%d_%H_%M")"
DATE_EXEC="$(date "+%d+%b")"
DATE_EXEC_H="$(date "+%d %b %Y %H:%M")"

# Output for checking
echo "["$DATE_EXEC_H"] Backup process start... "

echo "Backing up "$DB_NAME"..." 
mysqldump --add-drop-table --lock-tables=true -u $DB_USER -p$DB_PSWD $DB_NAME | gzip -9 > $DUMP_LOC/$DB_NAME-$DATE_BAK.sql.gz

# Counting filezie
FILESIZE="$(ls -lah $DUMP_LOC/$DB_NAME-$DATE_BAK.sql.gz | awk '{print $5}')"

echo "Sending backup file  Amazon S3..."
/tools/s3cmd/s3cmd --acl-private put $DUMP_LOC/$DB_NAME-$DATE_BAK.sql.gz $S3_BUCKET

echo "Removing old files..."
find $DUMP_LOC/*.sql.gz -mtime +$DAYS_OLD -exec rm {} \;

END_TIME="$(date +"%s")"
DIFF_TIME=$(( $END_TIME - $START_TIME ))
H=$(($DIFF_TIME/3600))
M=$(($DIFF_TIME%3600/60))
S=$(($DIFF_TIME%60))

DONE_MSG="$DATE_EXEC $DB_NAME ($FILESIZE_MAIN) in $H hour(s) $M minute(s) $S seconds"

echo "Done: "$DONE_MSG
