# Purpose
This custom GitHub Action were created to simplify serverles-app-template repository workflows.


### How to use?
```yaml
name: GH Action workflow example

on:
  pull_request:
    types:
      - opened
      - reopened
      - synchronize
      - edited
    branches:
      - 'main'

permissions:
  contents: read
  id-token: write

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      - name: Assume role using OIDC
        uses: flipdishbytes/serverless-app-actions/configure-aws-credentials@v1.0
        with:
          workload_name: platform
          ou_name: ephemeral
      - name: Install dependencies
        uses: flipdishbytes/serverless-app-actions/setup-pnpm-and-install-modules@v1.0
        # with:
        #   node-version: 20 ### use is if you need different NodeJS version (22 is by default)
      - name: Deploy
        run: pnpm sst deploy
      - name: Validate OpenApi spec
        uses: flipdishbytes/serverless-app-actions/validate-openapi-spec@v1.0
        with:
          openapi-url: /serverless-app-template/openapi.yaml

      ...
      - name: Generate Bucket variables
        id: variables
        run: pnpm variables:generate:frontend
        env:
          SST_STAGE: PR-${{ github.event.number }}
          APP_NAME: authorization
      - name: Build Frontend
        run: pnpm build:frontend
        env:
          VITE_CODE_BASE_URL: ${{ steps.variables.outputs.distributionUrl }}
      - name: Run Testing
        run: pnpm test:frontend
      - name: Upload to S3 Bucket
        uses: flipdishbytes/serverless-app-actions/s3-upload@v1.0
        with:
          bucket-url: ${{ steps.variables.outputs.bucketUploadUrl }}
          invalidate-url: ${{ steps.variables.outputs.distributionUrlToInvalidate }}
          distribution-id: ${{ steps.variables.outputs.distributionId }}
          working-directory: packages/frontend/dist
          cache-duration: '86400'
```
