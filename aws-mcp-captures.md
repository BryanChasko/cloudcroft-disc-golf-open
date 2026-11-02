# AWS MCP Captures — Cloudcroft Disc Golf

Real call/return pairs from the cloudcroft-disc-golf AWS infrastructure, captured via AWS MCP tools on 2026-11-02. All calls use `aws_profile: aerospaceug-admin` with explicit `region_name: us-east-1` unless otherwise noted.

## Table of Contents

1. Lambda Functions — Graviton (ARM64) on Amazon Linux 2023
2. DynamoDB Table — On-Demand with PITR
3. CloudFormation Stack
4. API Gateway V2 — HTTP API
5. Live API Calls
6. Amazon Location Service
7. Amazon Cognito Identity Pool
8. Lambda Invoke (Cold + Warm)
9. API Gateway Routes and Integrations
10. S3 and CloudFront
11. CloudFormation Resource Type Counts
12. CloudWatch Logs and Drift Status
13. Infrastructure as Code — CDK Stack Excerpts
14. Build and Test Standards

---

## Lambda Functions — Graviton (ARM64) on Amazon Linux 2023

### MCP Tool Invocation Shape

```python
# AWS MCP run_script call pattern
result = await call_boto3(
    service_name='lambda',
    operation_name='GetFunctionConfiguration',
    region_name='us-east-1',
    params={'FunctionName': 'cloudcroft-disc-golf-plays-like'}
)
```

### cloudcroft-disc-golf-plays-like

```json
{
  "FunctionName": "cloudcroft-disc-golf-plays-like",
  "FunctionArn": "arn:aws:lambda:us-east-1:<ACCOUNT_ID>:function:cloudcroft-disc-golf-plays-like",
  "Runtime": "provided.al2023",
  "Role": "arn:aws:iam::<ACCOUNT_ID>:role/cloudcroft-disc-golf-PlaysLikeServiceRole42858957-j5lZGaslTEGH",
  "Handler": "bootstrap",
  "CodeSize": 1461881,
  "Description": "Hackathon: plays-like distance v0",
  "Timeout": 10,
  "MemorySize": 128,
  "Architectures": ["arm64"],
  "PackageType": "Zip",
  "EphemeralStorage": { "Size": 512 },
  "State": "Active"
}
```

### cloudcroft-disc-golf-scorecard

```json
{
  "FunctionName": "cloudcroft-disc-golf-scorecard",
  "FunctionArn": "arn:aws:lambda:us-east-1:<ACCOUNT_ID>:function:cloudcroft-disc-golf-scorecard",
  "Runtime": "provided.al2023",
  "Role": "arn:aws:iam::<ACCOUNT_ID>:role/cloudcroft-disc-golf-ScorecardServiceRole6F68A281-sMzpgVlzOkzL",
  "Handler": "bootstrap",
  "CodeSize": 7897460,
  "Description": "Hackathon: scorecard API",
  "Timeout": 10,
  "MemorySize": 128,
  "Environment": {
    "Variables": { "SCORECARD_TABLE": "cloudcroft-disc-golf-scorecards" }
  },
  "Architectures": ["arm64"],
  "PackageType": "Zip",
  "EphemeralStorage": { "Size": 512 },
  "State": "Active"
}
```

**Key observations:**

- `Architectures: ["arm64"]` — Graviton processors for cost/performance efficiency
- `Runtime: provided.al2023` — Amazon Linux 2023 custom runtime (Rust compiled to static musl binary)
- `Handler: bootstrap` — Custom runtime entry point (not a managed runtime handler)
- 128 MB memory, 10 second timeout — minimal footprint for stateless compute

## DynamoDB Table — On-Demand with PITR

### MCP Tool Invocation Shape

```python
# Describe table
result = await call_boto3(
    service_name='dynamodb',
    operation_name='DescribeTable',
    region_name='us-east-1',
    params={'TableName': 'cloudcroft-disc-golf-scorecards'}
)

# Describe continuous backups (PITR status)
result = await call_boto3(
    service_name='dynamodb',
    operation_name='DescribeContinuousBackups',
    region_name='us-east-1',
    params={'TableName': 'cloudcroft-disc-golf-scorecards'}
)
```

### cloudcroft-disc-golf-scorecards

```json
{
  "Table": {
    "TableName": "cloudcroft-disc-golf-scorecards",
    "KeySchema": [
      { "AttributeName": "round_id", "KeyType": "HASH" },
      { "AttributeName": "entry", "KeyType": "RANGE" }
    ],
    "AttributeDefinitions": [
      { "AttributeName": "round_id", "AttributeType": "S" },
      { "AttributeName": "entry", "AttributeType": "S" }
    ],
    "TableStatus": "ACTIVE",
    "BillingModeSummary": {
      "BillingMode": "PAY_PER_REQUEST"
    },
    "ProvisionedThroughput": {
      "ReadCapacityUnits": 0,
      "WriteCapacityUnits": 0
    }
  }
}
```

### Point-in-Time Recovery Status

```json
{
  "ContinuousBackupsDescription": {
    "ContinuousBackupsStatus": "ENABLED",
    "PointInTimeRecoveryDescription": {
      "PointInTimeRecoveryStatus": "ENABLED",
      "RecoveryPeriodInDays": 35,
      "EarliestRestorableDateTime": "2026-10-29T22:24:06+00:00",
      "LatestRestorableDateTime": "2026-11-02T18:41:50.032000+00:00"
    }
  }
}
```

**Key observations:**

- Composite key: `round_id` (PK) + `entry` (SK) — one round has multiple entries (meta + hole scores)
- `PAY_PER_REQUEST` billing — on-demand capacity, no provisioned throughput
- PITR enabled with 35-day recovery window — production-grade durability

## CloudFormation Stack

### MCP Tool Invocation Shape

```python
# Describe stack
result = await call_boto3(
    service_name='cloudformation',
    operation_name='DescribeStacks',
    region_name='us-east-1',
    params={'StackName': 'cloudcroft-disc-golf'}
)

# Describe stack resources
result = await call_boto3(
    service_name='cloudformation',
    operation_name='DescribeStackResources',
    region_name='us-east-1',
    params={'StackName': 'cloudcroft-disc-golf'}
)
```

### Stack Outputs

```json
{
  "StackName": "cloudcroft-disc-golf",
  "Description": "AR map + scorecard for Cloudcroft NM disc golf (hackathon)",
  "StackStatus": "UPDATE_COMPLETE",
  "Outputs": [
    {
      "OutputKey": "ApiUrl",
      "OutputValue": "https://<API_ID>.execute-api.us-east-1.amazonaws.com"
    },
    {
      "OutputKey": "IdentityPoolId",
      "OutputValue": "us-east-1:<IDENTITY_POOL_ID>"
    },
    {
      "OutputKey": "PlaceIndexArn",
      "OutputValue": "arn:aws:geo:us-east-1:<ACCOUNT_ID>:place-index/cloudcroft-disc-golf"
    }
  ],
  "Tags": [{ "Key": "Project", "Value": "cloudcroft-disc-golf" }]
}
```

### Stack Resources (29 total)

| Logical ID              | Physical ID                     | Type                              |
| ----------------------- | ------------------------------- | --------------------------------- |
| ApiF70053CD             | `<API_ID>`                      | AWS::ApiGatewayV2::Api            |
| ApiDefaultStage189A7074 | `$default`                      | AWS::ApiGatewayV2::Stage          |
| PlaysLike97D79892       | cloudcroft-disc-golf-plays-like | AWS::Lambda::Function             |
| Scorecard644B5D8C       | cloudcroft-disc-golf-scorecard  | AWS::Lambda::Function             |
| Scorecards9E0CD225      | cloudcroft-disc-golf-scorecards | AWS::DynamoDB::Table              |
| GuestPool06A67AF6       | `us-east-1:<IDENTITY_POOL_ID>`  | AWS::Cognito::IdentityPool        |
| HoleGeofences           | cloudcroft-disc-golf-holes      | AWS::Location::GeofenceCollection |
| ImageryMap              | cloudcroft-disc-golf-imagery    | AWS::Location::Map                |
| TopoMap                 | cloudcroft-disc-golf-topo       | AWS::Location::Map                |
| PlaceIndex              | cloudcroft-disc-golf            | AWS::Location::PlaceIndex         |
| PlayerTracker           | cloudcroft-disc-golf-players    | AWS::Location::Tracker            |
| Routes                  | cloudcroft-disc-golf-routes     | AWS::Location::RouteCalculator    |

## API Gateway V2 — HTTP API

### MCP Tool Invocation Shape

```python
result = await call_boto3(
    service_name='apigatewayv2',
    operation_name='GetApis',
    region_name='us-east-1'
)
```

### API Configuration

```json
{
  "Items": [
    {
      "ApiId": "<API_ID>",
      "ApiEndpoint": "https://<API_ID>.execute-api.us-east-1.amazonaws.com",
      "Name": "cloudcroft-disc-golf",
      "ProtocolType": "HTTP",
      "Description": "Hackathon: plays-like + scorecard API",
      "CorsConfiguration": {
        "AllowOrigins": [
          "https://bryanchasko.com",
          "https://www.bryanchasko.com"
        ],
        "AllowMethods": ["GET", "POST"],
        "AllowHeaders": ["content-type", "authorization"]
      }
    }
  ]
}
```

## Live API Calls

### GET /plays-like

Request parameters (from `backend/plays-like/src/main.rs`):

- `from_lat`, `from_lon`, `from_ele_ft` — tee position
- `to_lat`, `to_lon`, `to_ele_ft` — basket position

```bash
curl "https://<API_ID>.execute-api.us-east-1.amazonaws.com/plays-like?from_lat=32.95787&from_lon=-105.73887&from_ele_ft=8640&to_lat=32.95887&to_lon=-105.73887&to_ele_ft=8690"
```

```json
{
  "horizontal_ft": 364.8127519615766,
  "elev_change_ft": 50.0,
  "plays_like_ft": 414.8127519615766,
  "model": "v0-uphill-full-downhill-half"
}
```

**Model explanation (from source):** Uphill adds the full climb; downhill credits half the drop. A 300 ft hole that drops 80 ft plays like 260 ft.

### GET /scorecard

Request parameter (from `backend/scorecard/src/main.rs`):

- `round_id` — unique round identifier

```bash
curl "https://<API_ID>.execute-api.us-east-1.amazonaws.com/scorecard?round_id=test-round-001"
```

```json
{
  "round_id": "test-round-001",
  "entries": []
}
```

---

## Amazon Location Service

### MCP Tool Invocation Shape

```python
# Describe maps
result = await call_boto3(
    service_name='location',
    operation_name='DescribeMap',
    region_name='us-east-1',
    params={'MapName': 'cloudcroft-disc-golf-topo'}
)

# Search place index
result = await call_boto3(
    service_name='location',
    operation_name='SearchPlaceIndexForText',
    region_name='us-east-1',
    params={
        'IndexName': 'cloudcroft-disc-golf',
        'Text': 'Zenith Park, Cloudcroft, NM',
        'MaxResults': 1
    }
)

# Calculate route
result = await call_boto3(
    service_name='location',
    operation_name='CalculateRoute',
    region_name='us-east-1',
    params={
        'CalculatorName': 'cloudcroft-disc-golf-routes',
        'DeparturePosition': [-105.73887, 32.95787],
        'DestinationPosition': [-105.73996, 32.96320]
    }
)
```

### Map: cloudcroft-disc-golf-topo

```json
{
  "MapName": "cloudcroft-disc-golf-topo",
  "MapArn": "arn:aws:geo:us-east-1:<ACCOUNT_ID>:map/cloudcroft-disc-golf-topo",
  "PricingPlan": "RequestBasedUsage",
  "DataSource": "Esri",
  "Configuration": { "Style": "VectorEsriTopographic" },
  "Description": "Hackathon: topo base map",
  "CreateTime": "2026-10-29T22:23:54.856000+00:00"
}
```

### Map: cloudcroft-disc-golf-imagery

```json
{
  "MapName": "cloudcroft-disc-golf-imagery",
  "MapArn": "arn:aws:geo:us-east-1:<ACCOUNT_ID>:map/cloudcroft-disc-golf-imagery",
  "PricingPlan": "RequestBasedUsage",
  "DataSource": "Esri",
  "Configuration": { "Style": "RasterEsriImagery" },
  "Description": "Hackathon: satellite base map",
  "CreateTime": "2026-10-29T22:23:54.826000+00:00"
}
```

### Place Index: cloudcroft-disc-golf

```json
{
  "IndexName": "cloudcroft-disc-golf",
  "IndexArn": "arn:aws:geo:us-east-1:<ACCOUNT_ID>:place-index/cloudcroft-disc-golf",
  "PricingPlan": "RequestBasedUsage",
  "Description": "Hackathon: geocode course anchors",
  "DataSource": "Esri",
  "DataSourceConfiguration": { "IntendedUse": "SingleUse" },
  "CreateTime": "2026-10-29T22:23:54.725000+00:00"
}
```

### SearchPlaceIndexForText: "Zenith Park, Cloudcroft, NM"

```json
{
  "Summary": {
    "Text": "Zenith Park, Cloudcroft, NM",
    "MaxResults": 1,
    "ResultBBox": [-105.7369, 32.95723, -105.7369, 32.95723],
    "DataSource": "Esri"
  },
  "Results": [
    {
      "Place": {
        "Label": "Zenith Park, James Canyon Hwy, Cloudcroft, NM, 88317, USA",
        "Geometry": { "Point": [-105.7369, 32.95723] },
        "Street": "James Canyon Hwy",
        "Municipality": "Cloudcroft",
        "SubRegion": "Otero County",
        "Region": "New Mexico",
        "Country": "USA",
        "PostalCode": "88317",
        "Interpolated": false,
        "Categories": ["PointOfInterestType", "Park"]
      },
      "Relevance": 1.0
    }
  ]
}
```

### Geofence Collection: cloudcroft-disc-golf-holes

```json
{
  "CollectionName": "cloudcroft-disc-golf-holes",
  "CollectionArn": "arn:aws:geo:us-east-1:<ACCOUNT_ID>:geofence-collection/cloudcroft-disc-golf-holes",
  "Description": "Hackathon: per-hole geofences",
  "PricingPlan": "RequestBasedUsage",
  "GeofenceCount": 0,
  "CreateTime": "2026-10-29T22:23:54.966000+00:00"
}
```

### ListGeofences

```json
{ "Entries": [] }
```

No geofences defined yet.

### Route Calculator: cloudcroft-disc-golf-routes

```json
{
  "CalculatorName": "cloudcroft-disc-golf-routes",
  "CalculatorArn": "arn:aws:geo:us-east-1:<ACCOUNT_ID>:route-calculator/cloudcroft-disc-golf-routes",
  "PricingPlan": "RequestBasedUsage",
  "Description": "Hackathon: walking routes (parking to hole 1, between holes)",
  "DataSource": "Esri",
  "CreateTime": "2026-10-29T22:23:54.807000+00:00"
}
```

### CalculateRoute: Byron Ligon to Community Course

From `docs/infra.md` anchors:

- Departure: Byron Ligon / Zenith Park (lon=-105.73887, lat=32.95787)
- Destination: Community course (lon=-105.73996, lat=32.96320)

```json
{
  "Legs": [
    {
      "StartPosition": [-105.73883641680318, 32.957475625595876],
      "EndPosition": [-105.74004992051833, 32.96327948616491],
      "Distance": 1.212716662242437,
      "DurationSeconds": 144.197127924,
      "Steps": [
        { "Distance": 0.37229295709180044, "DurationSeconds": 27.628052106 },
        { "Distance": 0.13782119750976562, "DurationSeconds": 28.714599609 },
        { "Distance": 0.702602507640871, "DurationSeconds": 87.854476209 }
      ]
    }
  ],
  "Summary": {
    "RouteBBox": [
      -105.74280047286474, 32.95747560781771, -105.73883641680318,
      32.96327948616491
    ],
    "DataSource": "Esri",
    "Distance": 1.212716662242437,
    "DurationSeconds": 144.197127924,
    "DistanceUnit": "Kilometers"
  }
}
```

**Route summary:** 1.21 km walking distance, approximately 2 minutes 24 seconds.

---

## Amazon Cognito Identity Pool

### MCP Tool Invocation Shape

```python
# Describe identity pool
result = await call_boto3(
    service_name='cognito-identity',
    operation_name='DescribeIdentityPool',
    region_name='us-east-1',
    params={'IdentityPoolId': 'us-east-1:<IDENTITY_POOL_ID>'}
)

# Get identity pool roles
result = await call_boto3(
    service_name='cognito-identity',
    operation_name='GetIdentityPoolRoles',
    region_name='us-east-1',
    params={'IdentityPoolId': 'us-east-1:<IDENTITY_POOL_ID>'}
)

# Get unauth role policy
result = await call_boto3(
    service_name='iam',
    operation_name='GetRolePolicy',
    region_name='us-east-1',
    params={
        'RoleName': 'cloudcroft-disc-golf-GuestPoolUnauthenticatedRole78-kg4e7ilpFKyl',
        'PolicyName': 'GuestPoolUnauthenticatedRoleDefaultPolicy0B45EBD4'
    }
)
```

### DescribeIdentityPool

```json
{
  "IdentityPoolId": "us-east-1:<IDENTITY_POOL_ID>",
  "IdentityPoolName": "cloudcroft-disc-golf-guests",
  "AllowUnauthenticatedIdentities": true,
  "IdentityPoolTags": {
    "Project": "cloudcroft-disc-golf",
    "aws:cloudformation:logical-id": "GuestPool06A67AF6",
    "aws:cloudformation:stack-name": "cloudcroft-disc-golf"
  }
}
```

### GetIdentityPoolRoles

```json
{
  "IdentityPoolId": "us-east-1:<IDENTITY_POOL_ID>",
  "Roles": {
    "authenticated": "arn:aws:iam::<ACCOUNT_ID>:role/cloudcroft-disc-golf-GuestPoolAuthenticatedRoleEA72-czZzRrFy6iLJ",
    "unauthenticated": "arn:aws:iam::<ACCOUNT_ID>:role/cloudcroft-disc-golf-GuestPoolUnauthenticatedRole78-kg4e7ilpFKyl"
  }
}
```

### Unauthenticated Role Policy Statement

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "geo:GetMapTile",
        "geo:GetMapSprites",
        "geo:GetMapGlyphs",
        "geo:GetMapStyleDescriptor"
      ],
      "Resource": [
        "arn:aws:geo:us-east-1:<ACCOUNT_ID>:map/cloudcroft-disc-golf-topo",
        "arn:aws:geo:us-east-1:<ACCOUNT_ID>:map/cloudcroft-disc-golf-imagery"
      ],
      "Effect": "Allow"
    },
    {
      "Action": [
        "geo:SearchPlaceIndexForText",
        "geo:SearchPlaceIndexForPosition",
        "geo:GetPlace"
      ],
      "Resource": "arn:aws:geo:us-east-1:<ACCOUNT_ID>:place-index/cloudcroft-disc-golf",
      "Effect": "Allow"
    },
    {
      "Action": [
        "geo:BatchUpdateDevicePosition",
        "geo:GetDevicePosition",
        "geo:ListDevicePositions",
        "geo:BatchEvaluateGeofences",
        "geo:ListGeofences",
        "geo:GetGeofence"
      ],
      "Resource": [
        "arn:aws:geo:us-east-1:<ACCOUNT_ID>:tracker/cloudcroft-disc-golf-players",
        "arn:aws:geo:us-east-1:<ACCOUNT_ID>:geofence-collection/cloudcroft-disc-golf-holes"
      ],
      "Effect": "Allow"
    },
    {
      "Action": "geo:CalculateRoute",
      "Resource": "arn:aws:geo:us-east-1:<ACCOUNT_ID>:route-calculator/cloudcroft-disc-golf-routes",
      "Effect": "Allow"
    }
  ]
}
```

**Policy grants:** Guest users can read map tiles, search places, update/read device positions, evaluate geofences, and calculate routes. No write access to geofence definitions or place index configuration.

---

## Lambda Invoke (Cold + Warm)

### MCP Tool Invocation Shape

```python
# API Gateway v2 event payload
event = {
    "version": "2.0",
    "routeKey": "GET /plays-like",
    "rawPath": "/plays-like",
    "queryStringParameters": {
        "from_lat": "32.95787",
        "from_lon": "-105.73887",
        "from_ele_ft": "8640",
        "to_lat": "32.95887",
        "to_lon": "-105.73887",
        "to_ele_ft": "8690"
    },
    "requestContext": {
        "accountId": "<ACCOUNT_ID>",
        "apiId": "<API_ID>",
        "http": {"method": "GET", "path": "/plays-like"}
    }
}

result = await call_boto3(
    service_name='lambda',
    operation_name='Invoke',
    region_name='us-east-1',
    params={
        'FunctionName': 'cloudcroft-disc-golf-plays-like',
        'InvocationType': 'RequestResponse',
        'LogType': 'Tail',
        'Payload': json.dumps(event)
    }
)
```

### First Invoke (Cold Start)

```
START RequestId: 67230e1c-b36b-402e-a49a-118e67ba8276 Version: $LATEST
END RequestId: 67230e1c-b36b-402e-a49a-118e67ba8276
REPORT RequestId: 67230e1c-b36b-402e-a49a-118e67ba8276
  Duration: 15.14 ms
  Billed Duration: 45 ms
  Memory Size: 128 MB
  Max Memory Used: 14 MB
  Init Duration: 29.41 ms
```

**Response:**

```json
{
  "statusCode": 200,
  "headers": { "content-type": "application/json" },
  "body": "{\"horizontal_ft\":364.8127519615766,\"elev_change_ft\":50.0,\"plays_like_ft\":414.8127519615766,\"model\":\"v0-uphill-full-downhill-half\"}"
}
```

### Second Invoke (Warm Start)

```
START RequestId: 4d0f73c8-0f11-4fa9-983d-64d5f14142cd Version: $LATEST
END RequestId: 4d0f73c8-0f11-4fa9-983d-64d5f14142cd
REPORT RequestId: 4d0f73c8-0f11-4fa9-983d-64d5f14142cd
  Duration: 1.19 ms
  Billed Duration: 2 ms
  Memory Size: 128 MB
  Max Memory Used: 14 MB
```

**Response:** Same as first invoke.

**Cold vs Warm comparison:**

| Metric          | Cold Start | Warm Start |
| --------------- | ---------- | ---------- |
| Duration        | 15.14 ms   | 1.19 ms    |
| Billed Duration | 45 ms      | 2 ms       |
| Init Duration   | 29.41 ms   | (none)     |
| Max Memory      | 14 MB      | 14 MB      |

---

## API Gateway Routes and Integrations

### MCP Tool Invocation Shape

```python
# Get routes
result = await call_boto3(
    service_name='apigatewayv2',
    operation_name='GetRoutes',
    region_name='us-east-1',
    params={'ApiId': '<API_ID>'}
)

# Get integrations
result = await call_boto3(
    service_name='apigatewayv2',
    operation_name='GetIntegrations',
    region_name='us-east-1',
    params={'ApiId': '<API_ID>'}
)
```

### Routes

```json
{
  "Items": [
    {
      "RouteId": "gvoqfkb",
      "RouteKey": "GET /scorecard",
      "AuthorizationType": "NONE",
      "ApiKeyRequired": false,
      "Target": "integrations/v58kd5l"
    },
    {
      "RouteId": "lu535go",
      "RouteKey": "POST /scorecard",
      "AuthorizationType": "NONE",
      "ApiKeyRequired": false,
      "Target": "integrations/v58kd5l"
    },
    {
      "RouteId": "yrlswlo",
      "RouteKey": "GET /plays-like",
      "AuthorizationType": "NONE",
      "ApiKeyRequired": false,
      "Target": "integrations/ibkg97p"
    }
  ]
}
```

### Integrations

```json
{
  "Items": [
    {
      "IntegrationId": "ibkg97p",
      "IntegrationType": "AWS_PROXY",
      "IntegrationMethod": "POST",
      "IntegrationUri": "arn:aws:lambda:us-east-1:<ACCOUNT_ID>:function:cloudcroft-disc-golf-plays-like",
      "PayloadFormatVersion": "2.0",
      "TimeoutInMillis": 30000,
      "ConnectionType": "INTERNET"
    },
    {
      "IntegrationId": "v58kd5l",
      "IntegrationType": "AWS_PROXY",
      "IntegrationMethod": "POST",
      "IntegrationUri": "arn:aws:lambda:us-east-1:<ACCOUNT_ID>:function:cloudcroft-disc-golf-scorecard",
      "PayloadFormatVersion": "2.0",
      "TimeoutInMillis": 30000,
      "ConnectionType": "INTERNET"
    }
  ]
}
```

**Integration pattern:** Both routes use `AWS_PROXY` integration type with `POST` method to Lambda (API Gateway v2 uses POST internally for Lambda invoke regardless of the client's HTTP method). Payload format version 2.0 corresponds to API Gateway v2 event format.

---

## S3 and CloudFront

### S3 HeadObject: disc-golf/index.html

```python
result = await call_boto3(
    service_name='s3',
    operation_name='HeadObject',
    region_name='us-west-2',
    params={
        'Bucket': 'bryanchasko.com',
        'Key': 'disc-golf/index.html'
    }
)
```

```json
{
  "AcceptRanges": "bytes",
  "LastModified": "2026-11-02T13:21:33+00:00",
  "ContentLength": 568,
  "ETag": "\"e276f30e7e93d637527ef7f874d024db\"",
  "VersionId": "1yYaw9mpFS4hGbByTB3caooH8Z3LyXEi",
  "CacheControl": "no-cache, must-revalidate",
  "ContentType": "text/html",
  "ServerSideEncryption": "AES256"
}
```

### CloudFront curl -sI Headers

```bash
curl -sI "https://bryanchasko.com/disc-golf/index.html"
```

```
HTTP/2 200
content-type: text/html
content-length: 568
date: Mon, 02 Nov 2026 20:03:24 GMT
last-modified: Mon, 02 Nov 2026 13:21:33 GMT
etag: "e276f30e7e93d637527ef7f874d024db"
x-amz-server-side-encryption: AES256
cache-control: no-cache, must-revalidate
x-amz-version-id: 1yYaw9mpFS4hGbByTB3caooH8Z3LyXEi
accept-ranges: bytes
server: AmazonS3
x-cache: Miss from cloudfront
via: 1.1 e9b5d0dd0751bcdabdf44958e6aec8d8.cloudfront.net (CloudFront)
x-amz-cf-pop: DFW56-P9
x-amz-cf-id: L7C2Tl8O-VXbdiTnAzm9h_xgvNNI090MVt8GXBPjYWgJhGIt8zDmcA==
```

### CloudFront GetDistributionConfig (Trimmed)

```python
result = await call_boto3(
    service_name='cloudfront',
    operation_name='GetDistributionConfig',
    region_name='us-east-1',
    params={'Id': '<DISTRIBUTION_ID>'}
)
```

```json
{
  "ETag": "EGF7WJDS61A2K",
  "DistributionConfig": {
    "CallerReference": "7a96ed08-e2a7-4c99-9d4b-f05ad3ddde49",
    "Aliases": {
      "Quantity": 3,
      "Items": [
        "bryanchasko.com",
        "www.bryanchasko.com",
        "typescript.bryanchasko.com"
      ]
    },
    "DefaultRootObject": "index.html",
    "Origins": {
      "Quantity": 1,
      "Items": [
        {
          "Id": "s3-origin",
          "DomainName": "bryanchasko.com.s3.us-west-2.amazonaws.com",
          "S3OriginConfig": { "OriginAccessIdentity": "" },
          "OriginAccessControlId": "E13G69ESMC19X2"
        }
      ]
    },
    "DefaultCacheBehavior": {
      "TargetOriginId": "s3-origin",
      "ViewerProtocolPolicy": "redirect-to-https",
      "AllowedMethods": { "Items": ["HEAD", "GET"] },
      "Compress": true,
      "CachePolicyId": "658327ea-f89d-4fab-a63d-7e88639e58f6",
      "FunctionAssociations": {
        "Quantity": 1,
        "Items": [
          {
            "FunctionARN": "arn:aws:cloudfront::<ACCOUNT_ID>:function/bryanchasko-com-url-rewrite",
            "EventType": "viewer-request"
          }
        ]
      }
    },
    "PriceClass": "PriceClass_100",
    "Enabled": true,
    "ViewerCertificate": {
      "CloudFrontDefaultCertificate": false,
      "ACMCertificateArn": "arn:aws:acm:us-east-1:<ACCOUNT_ID>:certificate/095c6724-7646-4b8c-b20b-d434447013c0",
      "SSLSupportMethod": "sni-only",
      "MinimumProtocolVersion": "TLSv1.2_2021"
    },
    "HttpVersion": "http2",
    "IsIPV6Enabled": true
  }
}
```

**Distribution highlights:**

- Origin: S3 bucket in us-west-2 with OAC (Origin Access Control)
- Edge function: viewer-request trigger for URL rewriting
- TLS: ACM certificate in us-east-1, TLSv1.2 minimum
- Price class 100 (lowest cost, North America/Europe edge locations)

---

## CloudFormation Resource Type Counts

| Resource Type                            | Count  |
| ---------------------------------------- | ------ |
| AWS::ApiGatewayV2::Api                   | 1      |
| AWS::ApiGatewayV2::Integration           | 2      |
| AWS::ApiGatewayV2::Route                 | 3      |
| AWS::ApiGatewayV2::Stage                 | 1      |
| AWS::CDK::Metadata                       | 1      |
| AWS::Cognito::IdentityPool               | 1      |
| AWS::Cognito::IdentityPoolRoleAttachment | 1      |
| AWS::DynamoDB::Table                     | 1      |
| AWS::IAM::Policy                         | 3      |
| AWS::IAM::Role                           | 4      |
| AWS::Lambda::Function                    | 2      |
| AWS::Lambda::Permission                  | 3      |
| AWS::Location::GeofenceCollection        | 1      |
| AWS::Location::Map                       | 2      |
| AWS::Location::PlaceIndex                | 1      |
| AWS::Location::RouteCalculator           | 1      |
| AWS::Location::Tracker                   | 1      |
| **Total**                                | **29** |

---

## CloudWatch Logs and Drift Status

### CloudWatch Logs — 7-Day REPORT Search

```python
result = await call_boto3(
    service_name='logs',
    operation_name='FilterLogEvents',
    region_name='us-east-1',
    params={
        'logGroupName': '/aws/lambda/cloudcroft-disc-golf-plays-like',
        'filterPattern': 'REPORT',
        'startTime': <7 days ago in ms>,
        'endTime': <now in ms>,
        'limit': 10
    }
)
```

**Result:**

```json
{ "events": [], "searchedLogStreams": [] }
```

**Status:** not captured: no invocations in window (prior to the two invokes performed for this document)

### CloudFormation Drift Status

```python
result = await call_boto3(
    service_name='cloudformation',
    operation_name='DescribeStackResourceDrifts',
    region_name='us-east-1',
    params={'StackName': 'cloudcroft-disc-golf'}
)
```

**Result:**

```json
{ "StackResourceDrifts": [] }
```

**Status:** not captured: no detection exists (empty drift array indicates no drift detection has been run)

---

## Infrastructure as Code — CDK Stack Excerpts

From `infra-cdk/lib/cloudcroft-disc-golf-stack.ts`:

### Lambda Function Definition (ARM64 + provided.al2023)

```typescript
const playsLike = new lambda.Function(this, "PlaysLike", {
  functionName: "cloudcroft-disc-golf-plays-like",
  runtime: lambda.Runtime.PROVIDED_AL2023,
  architecture: lambda.Architecture.ARM_64,
  handler: "bootstrap",
  code: lambda.Code.fromAsset(
    path.join(__dirname, "..", "assets", "plays-like"),
  ),
  memorySize: 128,
  timeout: cdk.Duration.seconds(10),
  description: "Hackathon: plays-like distance v0",
});
```

### DynamoDB Table Definition

```typescript
const scorecards = new dynamodb.Table(this, "Scorecards", {
  tableName: "cloudcroft-disc-golf-scorecards",
  partitionKey: { name: "round_id", type: dynamodb.AttributeType.STRING },
  sortKey: { name: "entry", type: dynamodb.AttributeType.STRING },
  billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
  removalPolicy: cdk.RemovalPolicy.RETAIN,
  pointInTimeRecovery: true,
});
```

---

## Build and Test Standards

### Lambda Build (Cross-Compilation to musl ARM64)

From `scripts/build-lambda-assets.sh`:

```bash
#!/usr/bin/env bash
# Build Rust lambda assets for the CDK stack (static musl ARM64 via cross).
# musl, not gnu: the cross gnu image links glibc 2.38+ but provided.al2023
# ships glibc 2.34, which fails at init. Static binaries have no libc dep.
set -euo pipefail
cd "$(dirname "$0")/../backend"

for crate in plays-like scorecard; do
  echo "=== $crate ==="
  cross build --target aarch64-unknown-linux-musl --release --package "$crate"
  out="../infra-cdk/assets/$crate"
  mkdir -p "$out"
  cp "target/aarch64-unknown-linux-musl/release/$crate" "$out/bootstrap"
done
echo "assets ready under infra-cdk/assets/"
```

**Key points:**

- `cross` for cross-compilation from x86_64 dev machine to ARM64 target
- `aarch64-unknown-linux-musl` — static binary, no glibc dependency
- Output: `infra-cdk/assets/<crate>/bootstrap` — CDK zips the directory for Lambda

### Rust Tests

```bash
cd backend
cargo test --workspace
```

From `backend/plays-like/src/main.rs`:

```rust
#[cfg(test)]
mod tests {
  #[test]
  fn same_point_is_zero() {
    assert_eq!(haversine_ft(32.95787, -105.73887, 32.95787, -105.73887), 0.0);
  }

  #[test]
  fn uphill_adds_full_climb() {
    assert_eq!(plays_like_ft(300.0, 40.0), 340.0);
  }

  #[test]
  fn downhill_credits_half_drop() {
    assert_eq!(plays_like_ft(300.0, -80.0), 260.0);
  }
}
```

### CDK Commands

From `infra-cdk/package.json`:

```json
{
  "scripts": {
    "build": "tsc --noEmit",
    "synth": "npx cdk synth --strict",
    "diff": "npx cdk diff",
    "deploy": "npx cdk deploy --require-approval never",
    "build:lambdas": "../scripts/build-lambda-assets.sh"
  }
}
```

### Deploy Flow

```bash
# 1. Build Rust lambdas
cd infra-cdk && npm run build:lambdas

# 2. Synthesize CloudFormation template
npm run synth

# 3. Review changes
npm run diff

# 4. Deploy
npm run deploy
```

---
