# Purpose

This custom GitHub Action were created to simplify serverles-app-template repository workflows.


### How to use?

#### `flipdishbytes/aws-accounts-ci@v1.0`

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
      - name: Deploy
        run: pnpm sst deploy
      - name: Validate OpenApi spec
        uses: flipdishbytes/serverless-app-actions/validate-openapi-spec@v1.0
        with:
          openapi-url: /serverless-app-template/openapi.yaml
```
