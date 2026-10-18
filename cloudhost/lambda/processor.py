"""
CloudHost Serverless S3 Security & Content Integrity Processor
AWS Lambda Function (Python 3.12)

Triggered automatically via S3 ObjectCreated events.
Computes cryptographic SHA-256 checksums, validates file integrity,
and updates the corresponding record in Amazon DynamoDB.
"""

import hashlib
import json
import logging
import os
import urllib.parse
from datetime import datetime
import boto3
from botocore.exceptions import ClientError

# Configure structured logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3_client = boto3.client("s3")
dynamodb = boto3.resource("dynamodb")
DYNAMODB_TABLE_NAME = os.environ.get("DYNAMODB_TABLE_NAME", "cloudhost-files-lab")


def lambda_handler(event, context):
    """
    Entry point for S3 event notification.
    """
    logger.info("Received S3 event: %s", json.dumps(event))
    table = dynamodb.Table(DYNAMODB_TABLE_NAME)

    processed_count = 0
    records = event.get("Records", [])

    for record in records:
        bucket_name = record["s3"]["bucket"]["name"]
        raw_key = record["s3"]["object"]["key"]
        s3_key = urllib.parse.unquote_plus(raw_key)

        logger.info("Processing object: s3://%s/%s", bucket_name, s3_key)

        # Ignore deployment bundles or non-upload prefixes
        if not s3_key.startswith("uploads/"):
            logger.info("Skipping non-upload key: %s", s3_key)
            continue

        try:
            # 1. Fetch object from S3 and compute SHA-256 digest
            s3_response = s3_client.get_object(Bucket=bucket_name, Key=s3_key)
            sha256_hasher = hashlib.sha256()

            file_stream = s3_response["Body"]
            bytes_read = 0
            while chunk := file_stream.read(65536):
                sha256_hasher.update(chunk)
                bytes_read += len(chunk)

            computed_sha256 = sha256_hasher.hexdigest()
            metadata = s3_response.get("Metadata", {})
            file_id = metadata.get("file-id")

            logger.info(
                "SHA-256 digest computed for %s (%d bytes): %s",
                s3_key,
                bytes_read,
                computed_sha256,
            )

            # 2. Locate matching record in DynamoDB
            target_file_id = file_id
            if not target_file_id:
                # Scan table for matching s3_key
                scan_resp = table.scan(
                    FilterExpression="s3_key = :key_val",
                    ExpressionAttributeValues={":key_val": s3_key},
                )
                items = scan_resp.get("Items", [])
                if items:
                    target_file_id = items[0]["file_id"]

            if not target_file_id:
                logger.warning("No DynamoDB record found for S3 key: %s", s3_key)
                continue

            # 3. Update DynamoDB item with verified integrity parameters
            now_iso = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S UTC")
            table.update_item(
                Key={"file_id": target_file_id},
                UpdateExpression=(
                    "SET processing_status = :status, "
                    "sha256_hash = :hash_val, "
                    "verified_at = :verified_val, "
                    "processed_by = :proc_val"
                ),
                ExpressionAttributeValues={
                    ":status": "VERIFIED",
                    ":hash_val": computed_sha256,
                    ":verified_val": now_iso,
                    ":proc_val": "AWS Lambda (Python 3.12)",
                },
            )

            logger.info(
                "DynamoDB record updated for file_id: %s with status VERIFIED",
                target_file_id,
            )
            processed_count += 1

        except ClientError as client_err:
            logger.error("AWS ClientError processing %s: %s", s3_key, client_err)
            raise client_err
        except Exception as exc:
            logger.error("Unexpected error processing %s: %s", s3_key, exc)
            raise exc

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Processing completed successfully",
            "processed_records": processed_count,
        }),
    }
