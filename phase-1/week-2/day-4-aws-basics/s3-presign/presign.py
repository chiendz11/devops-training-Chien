#!/usr/bin/env python3

import argparse
import sys

import boto3
from botocore.exceptions import BotoCoreError, ClientError, ProfileNotFound


def parse_args():
    parser = argparse.ArgumentParser(
        description="Generate a temporary presigned URL for a private S3 object."
    )
    parser.add_argument("--bucket", required=True, help="S3 bucket name")
    parser.add_argument("--key", required=True, help="S3 object key")
    parser.add_argument(
        "--expires",
        type=int,
        default=300,
        help="URL lifetime in seconds (default: 300)",
    )
    parser.add_argument(
        "--region",
        default="ap-southeast-1",
        help="AWS region",
    )
    parser.add_argument(
        "--profile",
        default="default",
        help="AWS CLI profile",
    )
    return parser.parse_args()


def main():
    args = parse_args()

    if args.expires <= 0:
        print("Error: --expires must be greater than 0", file=sys.stderr)
        return 1

    try:
        session = boto3.Session(
            profile_name=args.profile,
            region_name=args.region,
        )
        s3_client = session.client("s3")

        url = s3_client.generate_presigned_url(
            ClientMethod="get_object",
            Params={
                "Bucket": args.bucket,
                "Key": args.key,
            },
            ExpiresIn=args.expires,
        )
    except (BotoCoreError, ClientError, ProfileNotFound) as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1

    print(url)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
