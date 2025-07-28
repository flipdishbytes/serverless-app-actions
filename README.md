# Purpose

This custom GitHub Actions were created to simplify serverless-app-template repository workflows.

**Note**: Updates to these actions automatically propagate to the `flipdishbytes/serverless-app-actions` repository, which is used by other projects. Changes made here will be available to all repositories using the centralized actions. See [ADR-0050](../doc/adr/0050-use-github-composite-actions.md) for more details.

## How to use?

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
        uses: flipdishbytes/serverless-app-actions/configure-aws-credentials@v1.3
        with:
          workload_name: platform
          ou_name: ephemeral
      - name: Install dependencies
        uses: flipdishbytes/serverless-app-actions/setup-pnpm-and-install-modules@v1.3
        # with:
        #   node-version: 20 ### use is if you need different NodeJS version (22 is by default)
      - name: Deploy
        run: pnpm sst deploy
      - name: Validate OpenApi spec
        uses: flipdishbytes/serverless-app-actions/validate-openapi-spec@v1.3
        with:
          openapi-url: /openapi.yaml
          # retries: 4 # four openapi-url retries by default with 15 seconds delay before open-api check run
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
        uses: flipdishbytes/serverless-app-actions/s3-upload@v1.3
        with:
          bucket-url: ${{ steps.variables.outputs.bucketUploadUrl }}
          invalidate-url: ${{ steps.variables.outputs.distributionUrlToInvalidate }}
          distribution-id: ${{ steps.variables.outputs.distributionId }}
          working-directory: packages/frontend/dist
          cache-duration: '86400'
      ...
      - name: Running WDIO Tests
        run: pnpm wdio:local:headless:frontend
        env:
          PORTAL_URL: 'https://prod-staging.portal.flipdishdev.com'
          MICROFRONTEND_INDEX_URL: '${{ needs.integration-mf-deploy.outputs.distributionUrl }}assets/index.js'
      - name: Publish Test Results
        uses: flipdishbytes/serverless-app-actions/publish-wdio-results@v1.3
        if: success() || failure()
        continue-on-error: true
        with:
          files: |
            packages/frontend/e2e/wdio/reports/junit-results/*.xml
          allure_results: packages/frontend/e2e/wdio/reports/allure-results
          github_token: ${{ secrets.GITHUB_TOKEN }}
```
