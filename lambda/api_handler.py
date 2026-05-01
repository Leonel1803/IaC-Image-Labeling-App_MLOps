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
    normalized = label.strip().lower()
    candidate_labels = [normalized]
    title_case = label.strip().title()
    if title_case and title_case.lower() != normalized:
        candidate_labels.append(title_case.lower())

    image_items = []
    seen_keys = set()
    for candidate in candidate_labels:
        result = table.query(
            KeyConditionExpression=Key("PK").eq(f"LABEL#{candidate}"),
        )
        for item in result.get("Items", []):
            compound = (item.get("PK"), item.get("SK"))
            if compound in seen_keys:
                continue
            seen_keys.add(compound)
            image_items.append(item)

    if not image_items:
        return []

    response_items = []

    for index_item in image_items:
        image_id = index_item.get("imageId")
        metadata_pk = index_item.get("SK")
        if not metadata_pk:
            continue

        metadata_result = table.query(
            KeyConditionExpression=Key("PK").eq(metadata_pk) & Key("SK").eq("METADATA")
        )
        metadata_items = metadata_result.get("Items", [])
        if not metadata_items:
            continue
        metadata_item = metadata_items[0]

        s3_key = metadata_item.get("s3Key")
        if not s3_key:
            continue
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
    path = raw_path.rstrip("/") or "/"

    if method == "GET" and path in ("/", "/health"):
        return _response(200, {"ok": True})

    if method == "GET" and path == "/search":
        try:
            query_params = event.get("queryStringParameters") or {}
            label = unquote((query_params.get("label") or "").strip())
            if not label:
                return _response(400, {"error": "label is required"})

            items = _search(label)
            return _response(200, {"count": len(items), "items": items})
        except Exception as error:
            return _response(500, {"error": f"search failed: {str(error)}"})

    if method == "GET" and path == "/upload-url":
        query_params = event.get("queryStringParameters") or {}
        filename = (query_params.get("filename") or "image.jpg").strip()
        content_type = (query_params.get("contentType") or "application/octet-stream").strip()

        payload = _create_upload_url(filename, content_type)
        return _response(200, payload)

    return _response(404, {"error": "not found"})
