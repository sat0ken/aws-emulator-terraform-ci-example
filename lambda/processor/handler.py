"""S3 にアップロードされたテキストファイルを集計し、結果を JSON で出力バケットに書き出す。"""

import json
import os
import urllib.parse

import boto3

s3 = boto3.client("s3")
OUTPUT_BUCKET = os.environ["OUTPUT_BUCKET"]


def summarize(text: str) -> dict:
    return {
        "lines": len(text.splitlines()),
        "words": len(text.split()),
        "characters": len(text),
    }


def handler(event, context):
    outputs = []

    for record in event["Records"]:
        bucket = record["s3"]["bucket"]["name"]
        # S3 イベントのキーは URL エンコードされている（スペースは + になる）
        key = urllib.parse.unquote_plus(record["s3"]["object"]["key"])

        body = s3.get_object(Bucket=bucket, Key=key)["Body"].read().decode("utf-8")
        result = {"source": f"s3://{bucket}/{key}", **summarize(body)}

        output_key = f"results/{key}.json"
        s3.put_object(
            Bucket=OUTPUT_BUCKET,
            Key=output_key,
            Body=json.dumps(result, ensure_ascii=False).encode("utf-8"),
            ContentType="application/json",
        )

        print(json.dumps({"message": "processed", "output": f"s3://{OUTPUT_BUCKET}/{output_key}", **result}))
        outputs.append(output_key)

    return {"outputs": outputs}
