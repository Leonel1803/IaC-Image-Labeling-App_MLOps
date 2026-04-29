import json
import os
import uuid
from urllib.parse import unquote

import boto3
from boto3.dynamodb.conditions import Key

s3_client = boto3.client("s3")
dynamodb = boto3.resource("dynamodb")

table = dynamodb.Table(os.environ["DYNAMODB_TABLE"])
bucket_name = os.environ["BUCKET_NAME"]


def _response(status_code, payload):
    return {
        "statusCode": status_code,
        "headers": {"content-type": "application/json"},
        "body": json.dumps(payload),
    }


def _search(label):
    result = table.query(
        KeyConditionExpression=Key("PK").eq(f"LABEL#{label}"),
    )

    image_items = result.get("Items", [])
    if not image_items:
        return []
    response_items = []

    for index_item in image_items:
        image_id = index_item.get("imageId")
        metadata_pk = index_item.get("SK")
        metadata_result = table.get_item(
            Key={"PK": metadata_pk, "SK": "METADATA"}
        )
        metadata_item = metadata_result.get("Item")
        if not metadata_item:
            continue

        s3_key = metadata_item["s3Key"]
        view_url = s3_client.generate_presigned_url(
            "get_object",
            Params={"Bucket": bucket_name, "Key": s3_key},
            ExpiresIn=900,
        )

        response_items.append(
            {
                "imageId": image_id,
                "s3Key": s3_key,
                "labels": metadata_item.get("labels", []),
                "uploadedAt": metadata_item.get("uploadedAt"),
                "viewUrl": view_url,
            }
        )

    return response_items


def _create_upload_url(filename, content_type):
    extension = ""
    if "." in filename:
        extension = "." + filename.rsplit(".", 1)[1].lower()

    key = f"images/{uuid.uuid4()}{extension}"
    upload_url = s3_client.generate_presigned_url(
        "put_object",
        Params={
            "Bucket": bucket_name,
            "Key": key,
            "ContentType": content_type or "application/octet-stream",
        },
        ExpiresIn=900,
    )

    return {"key": key, "uploadUrl": upload_url}


def lambda_handler(event, context):
    method = event.get("requestContext", {}).get("http", {}).get("method", "GET")
    raw_path = event.get("rawPath", "/")

    if method == "GET" and raw_path == "/health":
        return _response(200, {"ok": True})

    if method == "GET" and raw_path == "/search":
        query_params = event.get("queryStringParameters") or {}
        label = unquote((query_params.get("label") or "").strip())
        if not label:
            return _response(400, {"error": "label is required"})

        items = _search(label)
        return _response(200, {"count": len(items), "items": items})

    if method == "POST" and raw_path == "/upload-url":
        body = json.loads(event.get("body") or "{}")
        filename = (body.get("filename") or "image.jpg").strip()
        content_type = (body.get("contentType") or "application/octet-stream").strip()

        payload = _create_upload_url(filename, content_type)
        return _response(200, payload)

    return _response(404, {"error": "not found"})
