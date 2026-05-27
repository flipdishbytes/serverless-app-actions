#!/usr/bin/env bash
# Resolved in the composite step shell (source, not bash subprocess) so writes go to $GITHUB_OUTPUT.
set -euo pipefail

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

stage="$(trim "${INPUT_SST_STAGE:-${SST_STAGE:-}}")"
workload_name="$(trim "${INPUT_WORKLOAD_NAME:-${WORKLOAD_NAME:-clients}}")"
app_name="$(trim "${INPUT_APP_NAME:-${APP_NAME:-local}}")"

if [[ -z "$stage" ]]; then
  echo 'SST_STAGE is required (set job env or pass sst-stage input)' >&2
  exit 1
fi

stage_lower="$(printf '%s' "$stage" | tr '[:upper:]' '[:lower:]')"
workload_lower="$(printf '%s' "$workload_name" | tr '[:upper:]' '[:lower:]')"

case "$stage_lower" in
  production)
    domain_name='clients.portal-mfs.flipdish.com'
    bucket_name="${stage_lower}-microfrontend-governance-${workload_lower}-api-bucket"
    distribution_id='E1QM7GI53TUOFA'
    ;;
  prod-staging)
    domain_name='clients-integration.portal-mfs.flipdishdev.com'
    bucket_name="${stage_lower}-microfrontend-governance-${workload_lower}-api-bucket"
    distribution_id='E2L6MMOL9AZQD7'
    ;;
  *)
    domain_name='clients-ephemeral.portal-mfs.flipdishdev.com'
    bucket_name="development-microfrontend-governance-${workload_lower}-api-bucket"
    distribution_id='ERY101JYYT32J'
    ;;
esac

distribution_url="https://${domain_name}/${app_name}/${stage}/"
bucket_upload_url="${bucket_name}/${app_name}/${stage}"
distribution_url_to_invalidate="/${app_name}/${stage}/*"

echo "Distribution URL: ${distribution_url}"
echo "Bucket name: ${bucket_name}"
echo "Distribution ID: ${distribution_id}"
echo "SST stage: ${stage}"
echo "Workload name: ${workload_name}"
echo "App name: ${app_name}"

if [[ -z "${GITHUB_OUTPUT:-}" ]]; then
  echo 'GITHUB_OUTPUT is not set (this script must run in a GitHub Actions step)' >&2
  exit 1
fi

# https://github.blog/changelog/2022-10-11-github-actions-deprecating-save-state-and-set-output-commands/
echo "domainName=${domain_name}" >>"$GITHUB_OUTPUT"
echo "bucketName=${bucket_name}" >>"$GITHUB_OUTPUT"
echo "bucketUploadUrl=${bucket_upload_url}" >>"$GITHUB_OUTPUT"
echo "distributionId=${distribution_id}" >>"$GITHUB_OUTPUT"
echo "distributionUrlToInvalidate=${distribution_url_to_invalidate}" >>"$GITHUB_OUTPUT"
echo "appName=${app_name}" >>"$GITHUB_OUTPUT"
echo "stage=${stage}" >>"$GITHUB_OUTPUT"
echo "workloadName=${workload_name}" >>"$GITHUB_OUTPUT"
echo "distributionUrl=${distribution_url}" >>"$GITHUB_OUTPUT"
