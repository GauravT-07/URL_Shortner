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
    path = event.get(
            "rawPath",
            ""
        )


    if method == "POST":
        return create_url(event, context)

    # GET /all
    elif method == "GET" and path == "/all":
        return get_all_urls()

    # GET /{short_code}
    elif method == "GET":
        return redirect_url(event, context)

    elif method == "DELETE":
        return delete_url(event, context)

    else:
        return {
            "statusCode": 405,
            "body": "Method not allowed"
        }

def delete_url(event, context):
    try:
        short_code = event.get("pathParameters", {}).get("short_code")

        if not short_code:
            return {
                "statusCode": 400,
                "headers": {
                    "Content-Type": "application/json"
                },
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

        if "Attributes" not in response:
            return {
                "statusCode": 404,
                "headers": {
                    "Content-Type": "application/json"
                },
                "body": json.dumps({
                    "error": "Short URL not found"
                })
            }

        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json"
            },
            "body": json.dumps({
                "message": "URL deleted successfully",
                "short_code": short_code
            })
        }

    except Exception as e:
        print("Error:", str(e))

        return {
            "statusCode": 500,
            "headers": {
                "Content-Type": "application/json"
            },
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

        # -----------------------------------------
        # Check if URL already exists
        # -----------------------------------------

        response = table.scan(
            FilterExpression=boto3.dynamodb.conditions.Attr(
                "original_url"
            ).eq(original_url)
        )

        existing_urls = response.get("Items", [])

        if existing_urls:

            existing = existing_urls[0]

            return {
                "statusCode": 200,
                "headers": {
                    "Content-Type": "application/json"
                },
                "body": json.dumps({
                    "original_url": existing.get("original_url"),
                    "short_code": existing.get("short_code"),
                    "short_url": f"https://url.gauravtotla.in/{existing.get('short_code')}"
                })
            }

        # -----------------------------------------
        # Generate new short code
        # -----------------------------------------

        short_code = generate_short_code()

        # -----------------------------------------
        # Insert into DynamoDB
        # -----------------------------------------

        table.put_item(
            Item={
                "original_url": original_url,
                "short_code": short_code
            }
        )

        # -----------------------------------------
        # Create short URL
        # -----------------------------------------

        short_url = f"https://3li9pyqc7g.execute-api.ap-south-1.amazonaws.com/{short_code}"

        # -----------------------------------------
        # Return response
        # -----------------------------------------

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

# -----------------------------------------
# Get all URLs
# GET /all
# -----------------------------------------

def get_all_urls():

    response = table.scan()

    urls = response.get(
        "Items",
        []
    )

    result = []

    for url in urls:

        result.append({

            "original_url":
                url.get("original_url"),

            "short_code":
                url.get("short_code"),

            "short_url":
                f"https://3li9pyqc7g.execute-api.ap-south-1.amazonaws.com/{url.get('short_code')}"
        })

    return {

        "statusCode": 200,

        "headers": {
            "Content-Type":
                "application/json"
        },

        "body": json.dumps(result)
    }

def redirect_url(event, context):
    try:
        short_code = event.get("pathParameters", {}).get("short_code")

        response = table.get_item(
            Key={
                "short_code": short_code
            }
        )

        item = response.get("Item")

        # Short code does not exist
        if not item:
            return {
                "statusCode": 404,
                "headers": {
                    "Content-Type": "application/json"
                },
                "body": json.dumps({
                    "error": "Short URL not found"
                })
            }

        original_url = item.get("original_url")

        # Redirect
        return {
            "statusCode": 302,
            "headers": {
                "Location": original_url
            },
            "body": ""
        }

    except Exception as e:
        print("Error:", str(e))

        return {
            "statusCode": 500,
            "body": json.dumps({
                "error": "Internal server error"
            })
        }