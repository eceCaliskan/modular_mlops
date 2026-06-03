def lambda_handler(event, context):
   
    print("Received event:", event)
    message = "Hello, " + event.get("key1", "World")
    
    return {
        'statusCode': 200,
        'body': message
    }