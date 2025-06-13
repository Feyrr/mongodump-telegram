#!/bin/bash

set -e

# Configuration
mongodump_bin='mongodump'
db='product'
host='mongo_host'
port='27017'
date=$(date +%F)
day_of_week=$(date +%u)   # 1 = Mon, 7 = Sun
day_of_month=$(date +%d)
s3_bucket='product-prod-mongodump'
local_dump_path='/dump/product-mongodump' # current local dir serving the script

# Define collections
daily_collections="users teams"
weekly_collections="adminlogs assets"
monthly_collections="aiimagelikes adminpermissions userlogs"

# Daily backup
daily_path="$local_dump_path/daily/$date"
mkdir -p "$daily_path"
echo "Backing up: daily collections ($date)"
for collection in $daily_collections; do
    echo "Dumping: $collection"
    $mongodump_bin --host "$host" --port "$port" --collection "$collection" --db "$db" --out "$daily_path"
done
frequency="daily"
echo "Uploading to s3://$s3_bucket/$frequency/$date/"
/usr/local/sbin/aws s3 sync "$daily_path" "s3://$s3_bucket/$frequency/$date/"
/bin/bash /opt/webhook/scripts/telegram.sh "$frequency" "$date"
echo "Done: $frequency backup for $date"

# Weekly backup
if [ "$day_of_week" -eq 7 ]; then
    sleep 1200
    weekly_path="$local_dump_path/weekly/$date"
    mkdir -p "$weekly_path"
    echo "Backing up: weekly collections ($date)"
    for collection in $weekly_collections; do
        echo "Dumping: $collection"
        $mongodump_bin --host "$host" --port "$port" --collection "$collection" --db "$db" --out "$weekly_path"
    done
    frequency="weekly"
    echo "Uploading to s3://$s3_bucket/$frequency/$date/"
    /usr/local/sbin/aws s3 sync "$weekly_path" "s3://$s3_bucket/$frequency/$date/"
    /bin/bash /opt/webhook/scripts/telegram.sh "$frequency" "$date"
    echo "Done: $frequency backup for $date"
fi

# Monthly backup
if [ "$day_of_month" -eq 1 ]; then
    sleep 1200
    monthly_path="$local_dump_path/monthly/$date"
    mkdir -p "$monthly_path"
    echo "Backing up: monthly collections ($date)"
    for collection in $monthly_collections; do
        echo "Dumping: $collection"
        $mongodump_bin --host "$host" --port "$port" --collection "$collection" --db "$db" --out "$monthly_path"
    done
    frequency="monthly"
    echo "Uploading to s3://$s3_bucket/$frequency/$date/"
    /usr/local/sbin/aws s3 sync "$monthly_path" "s3://$s3_bucket/$frequency/$date/"
    /bin/bash /opt/webhook/scripts/telegram.sh "$frequency" "$date"
    echo "Done: $frequency backup for $date"
fi
