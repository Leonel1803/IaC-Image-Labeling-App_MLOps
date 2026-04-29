import json
import os
import urllib.parse
from datetime import datetime, timezone

import boto3

rekognition = boto3.client("rekognition")
dynamodb = boto3.resource("dynamodb")

table = dynamodb.Table(os.environ["DYNAMODB_TABLE"])
confidence_threshold = float(os.environ.get("CONFIDENCE_THRESHOLD", "90"))


def _extract_records(event):
    return event.get("Records", [])


def _image_id_from_key(s3_key):
    filename = s3_key.split("/")[-1]
    return filename.rsplit(".", 1)[0]


def lambda_handler(event, context):
    records = _extract_records(event)

    for record in records:
        bucket = record["s3"]["bucket"]["name"]
        key = urllib.parse.unquote_plus(record["s3"]["object"]["key"])

        if not key.startswith("images/"):
            continue

        image_id = _image_id_from_key(key)

        response = rekognition.detect_labels(
            Image={"S3Object": {"Bucket": bucket, "Name": key}},
            MinConfidence=confidence_threshold,
        )

        labels = sorted({item["Name"] for item in response.get("Labels", [])})
        uploaded_at = datetime.now(timezone.utc).isoformat()

        table.put_item(
            Item={
                "PK": f"IMAGE#{image_id}",
                "SK": "METADATA",
                "imageId": image_id,
                "s3Key": key,
                "labels": labels,
                "uploadedAt": uploaded_at,
            }
        )

        if labels:
            with table.batch_writer() as batch:
                for label in labels:
                    batch.put_item(
                        Item={
                            "PK": f"LABEL#{label}",
                            "SK": f"IMAGE#{image_id}",
                            "imageId": image_id,
                            "s3Key": key,
                            "uploadedAt": uploaded_at,
                        }
                    )

    return {"statusCode": 200, "body": json.dumps({"processed": len(records)})}
