#!/bin/bash

# Enable debug mode
set -x

# Check if required environment variables are set
for var in POSTGRES_PASSWORD POSTGRES_USER POSTGRES_HOST POSTGRES_PORT POSTGRES_DATABASE MLFLOW_S3_BUCKET MLFLOW_S3_PREFIX; do
    if [ -z "${!var}" ]; then
        echo "Error: Required environment variable $var is not set"
        exit 1
    fi
done

echo "Starting MLflow server setup..."

# URL encode the password
ENCODED_PASSWORD=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$POSTGRES_PASSWORD', safe=''))")
echo "Database credentials validated"

# Start MLflow server with properly encoded connection string
exec mlflow server \
  --host 0.0.0.0 \
  --port 5000 \
  --backend-store-uri "postgresql://$POSTGRES_USER:$ENCODED_PASSWORD@$POSTGRES_HOST:$POSTGRES_PORT/$POSTGRES_DATABASE" \
  --default-artifact-root "s3://$MLFLOW_S3_BUCKET/$MLFLOW_S3_PREFIX"
