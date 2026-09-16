AWS Serverless Assignment
Task 1 – Lambda & Task 2 – API Gateway

Implementation, Testing, Learning Notes & Interview Preparation

This document is written as a practical learning record of what I implemented, why I implemented it, how I tested it, and what I understood from the assignment. The commands and observations below are based on the serverless project work and tests performed during the assignment.

1. Project Overview

The project is an AWS serverless application built using Terraform. The main idea is to use managed AWS services instead of managing servers manually. Lambda handles application logic, API Gateway provides HTTP APIs, SQS handles asynchronous messages, S3 handles object-upload events, EventBridge runs scheduled work, DynamoDB provides the users table, and CloudWatch is used for logs, metrics and monitoring.

Main architecture:

Client → API Gateway → API Lambda → application logic
S3 → S3 Lambda
Producer → SQS → SQS Lambda
EventBridge Schedule → Scheduled Lambda
Lambda → DynamoDB
Lambda/API Gateway → CloudWatch

Task 1 – AWS Lambda

For Task 1, I worked through the eight Lambda requirements one by one. The important part was not only creating the resources, but also testing them and understanding why each feature is useful.

Point 1 – Four Lambda Functions

I created four different Lambda functions for different event types: an API Lambda for HTTP requests, an S3 Lambda for object-created events, an SQS Lambda for queue messages, and an EventBridge scheduled Lambda for time-based background work.

What I understood: Easy way to remember: API = Request, S3 = File, SQS = Message, EventBridge = Time.

Test command:

aws lambda list-functions --query 'Functions[].{Name:FunctionName,Runtime:Runtime}' --output table

Point 2 – Cold Start Optimization

I learned the difference between a cold start and a warm invocation. A cold start happens when AWS needs to initialize a new execution environment. The project includes Lambda Insights and a custom runtime example. Provisioned Concurrency was configured in the Terraform design but kept disabled during testing because the AWS account concurrency quota was only 10 and the required reservation could not be safely configured.

What I understood: I verified Lambda Insights by checking the API Lambda layers and observed an INIT/REPORT log with an Init Duration of about 156 ms.

Test command:

aws lambda get-function-configuration --function-name serverless-demo-dev-api --qualifier live --query 'Layers[*].Arn' --output table
aws logs tail /aws/lambda/serverless-demo-dev-api --since 1h | grep 'Init Duration'

Point 3 – Lambda Layers

A Lambda Layer is a shared toolbox. Instead of putting common code or dependencies inside every Lambda package, common code can be stored in a layer. The API Lambda uses the project common layer and Lambda Insights layer.

What I understood: The common layer is compatible with Python 3.12 and was attached to the API, S3 and SQS functions where required.

Test command:

aws lambda get-function-configuration --function-name serverless-demo-dev-api --qualifier live --query 'Layers[*].Arn' --output table

Point 4 – Reserved Concurrency

Reserved concurrency limits the maximum concurrent executions for a function and can reserve capacity for an important function. During testing I found an important AWS behavior: setting reserved_concurrent_executions to 0 does not mean 'unlimited'; it blocks the function from executing. Because the account concurrency limit was only 10, reserved concurrency was temporarily disabled for the API function.

What I understood: After removing the reserved concurrency setting, the API Lambda could execute successfully again.

Test command:

aws lambda get-function-concurrency --function-name serverless-demo-dev-api

Point 5 – Structured JSON Logs and Correlation IDs

I implemented structured JSON application logs with fields such as event, correlation_id, request_id, method, path and duration. A correlation ID helps connect a request across API Gateway and Lambda logs.

What I understood: I tested with X-Correlation-ID: API-TEST-001 and the same correlation ID appeared in the API response and Lambda logs.

Test command:

curl -i -H 'x-api-key: $API_KEY' -H 'X-Correlation-ID: API-TEST-001' '$API_URL/users?limit=10'

Point 6 – Custom CloudWatch Metrics

I created custom metric filters for request duration, memory usage and request count. Lambda logs are the source, metric filters extract values, and CloudWatch can display those metrics on dashboards or alarms.

What I understood: The project uses the ServerlessApp namespace with RequestDurationMs, MemoryUsedMB and RequestCount. A CloudWatch dashboard named serverless-lambda-dev was also created.

Test command:

aws logs tail /aws/lambda/serverless-demo-dev-api --since 1h
aws cloudwatch list-metrics --namespace ServerlessApp

Point 7 – Concurrent Execution and Throttling Test

I tested the API under concurrent load using Apache Benchmark. The test used 50 requests with concurrency 10, and another test used 100 requests with concurrency 20. The Lambda throttles metric was observed as 0 during the earlier test. The larger API Gateway load test produced 80 non-2xx responses, showing that the configured API Gateway throttling was being enforced under heavy traffic.

What I understood: The important lesson is that API Gateway throttling and Lambda reserved concurrency are different controls. The API Gateway limit can protect the API from excessive incoming traffic.

Test command:

ab -n 50 -c 10 -H 'x-api-key: $API_KEY' '$API_URL/users?limit=10'
ab -n 100 -c 20 -H 'x-api-key: $API_KEY' '$API_URL/users?limit=10'

Point 8 – Environment Variables

I used environment variables so configuration is not hard-coded into the application. The API Lambda uses ENVIRONMENT, TABLE_NAME and LOG_LEVEL.

What I understood: The deployed API Lambda was verified with ENVIRONMENT=dev, TABLE_NAME=serverless-demo-dev-users and LOG_LEVEL=INFO.

Test command:

aws lambda get-function-configuration --function-name serverless-demo-dev-api --qualifier live --query 'Environment.Variables' --output table

3. Task 1 – Lambda Interview Summary

I implemented four event-driven Lambda functions and used layers, structured logging, correlation IDs, CloudWatch metrics, environment variables, and concurrency/cold-start related features. I also tested the functions directly and through their event sources. The main learning was how AWS Lambda can run application code without managing servers, while different AWS services trigger Lambda for different types of work.

4. Task 2 – API Gateway

For Task 2, I worked through the API Gateway requirements point by point. API Gateway acts as the HTTP front door to the serverless application. Clients call the REST API, API Gateway applies controls such as API keys, validation, CORS and throttling, and then the request is sent to the API Lambda.

API architecture:

Client → API Gateway REST API → Lambda → application logic
API Gateway → CloudWatch access logs
API Gateway → API Key → Usage Plan
API Gateway → Request Validation / CORS / Throttling

5. API Gateway Resources Created

The Terraform project creates a regional REST API and the following resources. The API ID used during testing was dku4e3i0ba and the stage was dev.

Resource

Methods

Purpose

/users

GET, POST

List users and create a user

/users/{id}

GET, PUT, DELETE

Read, update and delete a user by ID

/products

GET, POST

List products and create a product

/products/{id}

GET, PUT, DELETE

Read, update and delete a product by ID

This gives ten CRUD-style methods in total. The Terraform defines the resources and methods and integrates them with the API Lambda using AWS_PROXY. The API Lambda is reached through the live alias.

Point 1 – REST API and 8+ CRUD Endpoints

I created an API Gateway REST API with users and products resources. The user and product collection endpoints support GET and POST, while the ID resources support GET, PUT and DELETE.

What I understood: I understood that API Gateway provides the HTTP endpoint and routes the request to the Lambda function. The Lambda then decides how to process the request.

Test/check command:

aws apigateway get-resources --rest-api-id $(terraform output -raw api_id) --output table

Point 2 – Request Validation

I configured a request validator and request models. For users, GET /users requires the limit query parameter. POST /users validates the JSON body against a CreateUserRequest model requiring name and email. A CreateProductRequest model requires name and price.

What I understood: I tested GET /users without limit and received HTTP 400. When limit=10 was supplied, the request returned HTTP 200. This shows API Gateway can reject invalid requests before unnecessary backend processing.

Test/check command:

curl -i -H 'x-api-key: $API_KEY' '$API_URL/users'
curl -i -H 'x-api-key: $API_KEY' '$API_URL/users?limit=10'

Point 3 – Consistent Response Codes

The application returns 200 for successful GET/updates, 201 for creation, 400 for invalid input, 404 for an unmatched resource or endpoint, and 500 for internal errors. The response body follows a consistent structure containing success, data, error and correlation_id.

What I understood: I tested POST /users and received HTTP 201. I tested a missing required query parameter and received HTTP 400. I also tested an intentional error using force_error=true and received HTTP 500. A request to /users/999999 returned 200 because the current demo Lambda does not actually check DynamoDB for the existence of that specific ID; its 404 branch is for an unmatched endpoint/resource.

Test/check command:

curl -i -X POST -H 'x-api-key: $API_KEY' -H 'Content-Type: application/json' -H 'X-Correlation-ID: API-TEST-201' -d '{"name":"Test User","email":"test@example.com"}' '$API_URL/users'
curl -i -H 'x-api-key: $API_KEY' -H 'X-Correlation-ID: API-TEST-500' '$API_URL/users?limit=10&force_error=true'

Point 4 – API Key and Usage Plan

I created an enabled API key and connected it to an API Gateway usage plan. The usage plan is configured with approximately 100 requests/minute average behavior using a 1.6667 requests/second throttle, burst 5, and a monthly quota of 3000 requests.

What I understood: I understood that the API key identifies and controls a client, while the usage plan applies usage controls. API keys are not a replacement for strong user authentication such as OAuth/JWT, Cognito or IAM when those are required.

Test/check command:

aws apigateway get-api-key --api-key '$API_KEY_ID' --include-value --query '{Name:name,Enabled:enabled}' --output table
aws apigateway get-usage-plans --query 'items[].{Name:name,Id:id,Throttle:throttle,Quota:quota}' --output table

Point 5 – CORS

I configured CORS for the API using OPTIONS methods with MOCK integrations and the required Access-Control-Allow headers. The Lambda response also includes CORS headers.

What I understood: I understood that CORS is mainly a browser security mechanism. It allows a frontend hosted at one origin to call an API hosted at another origin when the API explicitly allows it.

Test/check command:

curl -i -X OPTIONS -H 'Origin: https://example.com' -H 'Access-Control-Request-Method: GET' '$API_URL/users'

Point 6 – API Gateway Rate Limiting

I configured API Gateway stage/method throttling with a rate limit of 10 requests per second and burst limit 20. This is separate from the usage-plan throttle.

What I understood: I tested with Apache Benchmark using 100 requests and 20 concurrent connections. The result was 100 complete requests with 80 non-2xx responses. A normal request sent afterward returned HTTP 200. The lesson is that the benchmark throughput is not the configured API limit; API Gateway throttling is the control that limits excessive traffic.

Test/check command:

ab -n 100 -c 20 -H 'x-api-key: $API_KEY' '$API_URL/users?limit=10'

Point 7 – CloudWatch Request/Response Logging

I configured an API Gateway CloudWatch access-log group and INFO-level method logging. The access-log format includes request ID, extended request ID, source IP, request time, HTTP method, resource path, status, protocol, response length and API key ID.

What I understood: I understood that API Gateway logs are very useful when troubleshooting production API requests because I can see what endpoint was called, when it was called, the status returned and request identifiers.

Test/check command:

aws logs describe-log-groups --log-group-name-prefix '/aws/apigateway/serverless-demo-dev' --query 'logGroups[].logGroupName' --output table
aws logs tail /aws/apigateway/serverless-demo-dev --since 10m

Point 8 – OpenAPI/Swagger and SDK

The project currently has the REST API, resources, methods, models, validation, CORS, gateway responses, API key, usage plan, throttling and logging implemented in Terraform. A separate OpenAPI/Swagger specification and SDK-generation workflow was not present in the Terraform file reviewed, so I did not claim this point as implemented.

What I understood: I understood that OpenAPI documents the API contract—paths, methods, parameters, request bodies and responses—and that an SDK can be generated from that contract for languages such as Python, JavaScript or Java.

Test/check command:

find . -maxdepth 3 -type f \( -iname '*.yaml' -o -iname '*.yml' -o -iname '*.json' \) | sort

6. Important Real-World Understanding

API Gateway and SQS solve different problems. API Gateway is the HTTP/HTTPS front door. It receives API requests and can apply validation, authentication-related controls, CORS, logging and throttling. SQS is a message queue used when work can be asynchronous. API Gateway does not automatically put throttled requests into SQS.

A common real-world design is: Client → API Gateway → Lambda → SQS → Worker Lambda. In that design, the API can accept a request quickly, place background work into SQS, and let worker Lambda functions process the messages. SQS is useful for buffering sudden workloads, decoupling services and supporting retry-based processing.

7. Important Troubleshooting Lessons

Lambda reserved concurrency of 0 means the function is blocked from executing; it is not the same as having no reserved-concurrency setting.

Account-level Lambda concurrency must be considered before configuring reserved or provisioned concurrency.

API Gateway throttling and Lambda throttling are separate controls.

A 200 response for /users/999999 does not prove that user exists. The current demo Lambda returns a successful placeholder response rather than querying DynamoDB for that ID.

An API Gateway Missing Authentication Token error for an undefined path is different from an application-level 500 error.

Curl is useful for functional testing, while Apache Benchmark is useful for load/concurrency testing.

Correlation IDs make troubleshooting easier because the same ID can be followed through API and Lambda logs.

8. Final Architecture and What I Learned

The assignment helped me understand how the AWS serverless pieces fit together rather than treating each service as a separate topic. API Gateway provides the controlled HTTP entry point, Lambda provides event-driven compute, S3/EventBridge/SQS provide different event sources, DynamoDB provides managed storage, and CloudWatch provides observability.

The biggest practical learning was troubleshooting from evidence. For example, when Lambda returned a concurrency error, I checked the account quota and function concurrency settings instead of assuming the code was broken. When API Gateway returned 200 for a nonexistent-looking user ID, I checked the Lambda code and found that the demo handler was not performing a database existence check.

9. Quick Interview Revision

What is API Gateway? API Gateway is the managed HTTP/REST entry point in front of backend services such as Lambda. It can handle routing, validation, API keys, throttling, CORS and logging.

Why use Lambda with API Gateway? API Gateway handles the HTTP request and Lambda runs the backend logic without requiring me to manage servers.

Why use SQS? SQS is used for asynchronous work. It buffers messages and decouples the producer from the consumer so workers can process jobs independently.

What is CORS? CORS is a browser security mechanism that controls whether a frontend from one origin can call an API on another origin.

What is rate limiting? Rate limiting controls how many requests an API accepts in a time period. In this project API Gateway is configured for 10 requests per second with a burst of 20.

What is an API key? An API key identifies an API client and can be associated with a usage plan for throttling and quotas.

Why CloudWatch logs? They help troubleshoot API requests by showing request IDs, paths, methods, status codes and other request information.

What is OpenAPI? OpenAPI is a standard machine-readable description of an API. It can document endpoints and schemas and can be used to generate client SDKs.

10. Completion Summary

Area

Status

Notes

Lambda – Points 1–8

Completed / tested

Provisioned concurrency and reserved concurrency were constrained by the account concurrency quota and were handled safely.

API Gateway – Points 1–7

Implemented / tested

REST CRUD resources, validation, response handling, API key/usage plan, CORS, throttling and CloudWatch logging.

API Gateway – Point 8

Not implemented as a separate artifact

OpenAPI/Swagger + SDK generation was explained, but a separate specification/SDK workflow was not found in the reviewed Terraform project.

Note: This document records the implementation and tests actually performed. It intentionally distinguishes demonstrated behavior from features that are
