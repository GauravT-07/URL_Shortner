import json
import boto3
import string
import random


dynamodb = boto3.resource("dynamodb")

table = dynamodb.Table("urls")


def generate_short_code(length=6):

    characters = string.ascii_letters + string.digits

    return ''.join(
        random.choices(characters, k=length)
    )


def lambda_handler(event, context):

    method = event["requestContext"]["http"]["method"]
    print("inside lambda handler")

    if method == "POST":
        return create_url(event, context)

    # elif method == "GET":
    #     return redirect_url(event)

    elif method == "DELETE":
        return delete_url(event, context)

    else:
        return {
            "statusCode": 405,
            "body": "Method not allowed"
        }

def delete_url(event, context):
    try:
        body = json.loads(event.get("body", "{}"))

        short_code = body.get("short_code")

        if not short_code:
            return {
                "statusCode": 400,
                "body": json.dumps({
                    "error": "short_code is required"
                })
            }

        response = table.delete_item(
            Key={
                "short_code": short_code
            },
            ReturnValues="ALL_OLD"
        )

        # Check whether the item actually existed
        if "Attributes" not in response:
            return {
                "statusCode": 404,
                "body": json.dumps({
                    "error": "Short URL not found"
                })
            }

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "URL deleted successfully",
                "short_code": short_code
            })
        }

    except Exception as e:
        print("Error:", str(e))

        return {
            "statusCode": 500,
            "body": json.dumps({
                "error": "Internal server error"
            })
        }


def create_url(event, context):
    try:

        # Get request body
        body = json.loads(
            event.get("body", "{}")
        )

        # Get original URL
        original_url = body.get("original_url")

        # Validate URL
        if not original_url:
            return {
                "statusCode": 400,
                "body": json.dumps({
                    "error": "original_url is required"
                })
            }

        # Generate short code
        short_code = generate_short_code()

        # Insert into DynamoDB
        table.put_item(
            Item={
                "original_url": original_url,
                "short_code": short_code
            }
        )

        # Create short URL
        short_url = f"https://url.gauravtotla.in/{short_code}"

        # Return response
        return {
            "statusCode": 201,
            "headers": {
                "Content-Type": "application/json"
            },
            "body": json.dumps({
                "original_url": original_url,
                "short_code": short_code,
                "short_url": short_url
            })
        }

    except Exception as e:

        print("Error:", str(e))

        return {
            "statusCode": 500,
            "body": json.dumps({
                "error": "Internal server error"
            })
        }