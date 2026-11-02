# AWS MCP Captures — Cloudcroft Disc Golf

Real call/return pairs from the cloudcroft-disc-golf AWS infrastructure, captured via AWS MCP tools on 2026-11-02. All calls use `aws_profile: aerospaceug-admin` with explicit `region_name: us-east-1`.

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
  "EphemeralStorage": {"Size": 512},
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
    "Variables": {"SCORECARD_TABLE": "cloudcroft-disc-golf-scorecards"}
  },
  "Architectures": ["arm64"],
  "PackageType": "Zip",
  "EphemeralStorage": {"Size": 512},
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
      {"AttributeName": "round_id", "KeyType": "HASH"},
      {"AttributeName": "entry", "KeyType": "RANGE"}
    ],
    "AttributeDefinitions": [
      {"AttributeName": "round_id", "AttributeType": "S"},
      {"AttributeName": "entry", "AttributeType": "S"}
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
    {"OutputKey": "ApiUrl", "OutputValue": "https://<API_ID>.execute-api.us-east-1.amazonaws.com"},
    {"OutputKey": "IdentityPoolId", "OutputValue": "us-east-1:<IDENTITY_POOL_ID>"},
    {"OutputKey": "PlaceIndexArn", "OutputValue": "arn:aws:geo:us-east-1:<ACCOUNT_ID>:place-index/cloudcroft-disc-golf"}
  ],
  "Tags": [{"Key": "Project", "Value": "cloudcroft-disc-golf"}]
}
```

### Stack Resources (29 total)

| Logical ID | Physical ID | Type |
| ---------- | ----------- | ---- |
| ApiF70053CD | `<API_ID>` | AWS::ApiGatewayV2::Api |
| ApiDefaultStage189A7074 | `$default` | AWS::ApiGatewayV2::Stage |
| PlaysLike97D79892 | cloudcroft-disc-golf-plays-like | AWS::Lambda::Function |
| Scorecard644B5D8C | cloudcroft-disc-golf-scorecard | AWS::Lambda::Function |
| Scorecards9E0CD225 | cloudcroft-disc-golf-scorecards | AWS::DynamoDB::Table |
| GuestPool06A67AF6 | `us-east-1:<IDENTITY_POOL_ID>` | AWS::Cognito::IdentityPool |
| HoleGeofences | cloudcroft-disc-golf-holes | AWS::Location::GeofenceCollection |
| ImageryMap | cloudcroft-disc-golf-imagery | AWS::Location::Map |
| TopoMap | cloudcroft-disc-golf-topo | AWS::Location::Map |
| PlaceIndex | cloudcroft-disc-golf | AWS::Location::PlaceIndex |
| PlayerTracker | cloudcroft-disc-golf-players | AWS::Location::Tracker |
| Routes | cloudcroft-disc-golf-routes | AWS::Location::RouteCalculator |

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
  "Items": [{
    "ApiId": "<API_ID>",
    "ApiEndpoint": "https://<API_ID>.execute-api.us-east-1.amazonaws.com",
    "Name": "cloudcroft-disc-golf",
    "ProtocolType": "HTTP",
    "Description": "Hackathon: plays-like + scorecard API",
    "CorsConfiguration": {
      "AllowOrigins": ["https://bryanchasko.com", "https://www.bryanchasko.com"],
      "AllowMethods": ["GET", "POST"],
      "AllowHeaders": ["content-type", "authorization"]
    }
  }]
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


