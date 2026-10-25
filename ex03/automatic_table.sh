#!/bin/bash

# Configuration
DB_NAME="piscineds"
DB_USER="lps"
DATA_DIR="/home/lps/Desktop/piscine/eval/customer" # Directory on your host machine

# Ensure the directory exists on the host
if [ ! -d "$DATA_DIR" ]; then
    echo "Error: Directory $DATA_DIR not found."
    exit 1
fi

# Loop through all CSV files in the directory
for filepath in "$DATA_DIR"/*.csv; do
    # Skip if no files match
    [ -e "$filepath" ] || continue

    # Extract filename without path and extension (e.g., "items.csv" -> "items")
    filename=$(basename "$filepath")
    table_name="${filename%.*}"

    echo "Processing table: $table_name from $filename..."

    # Step 1: Create the table inside the container
    docker exec -i postgres_db psql -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 <<EOF
    CREATE TABLE IF NOT EXISTS "$table_name" (
        event_time   TIMESTamptz,
        event_type   CHAR(100),
        product_id   INTEGER,
        price        REAL,
        user_id      BIGINT,
        user_session TEXT
    );
EOF

    # Step 2: Stream the CSV data into the container table using stdin (PROGRAM or standard pipe)
    # Using 'docker exec -i' allows piping the local file directly into psql's \copy stdin command
    # docker exec -i postgres_db psql -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 \
    #     -c "\copy \"$table_name\" FROM STDIN WITH (FORMAT csv, HEADER true);" < "$filepath"

    if [ $? -eq 0 ]; then
        echo "Successfully created and loaded table: $table_name"
    else
        echo "Failed processing table: $table_name"
    fi
done

echo "All files processed."