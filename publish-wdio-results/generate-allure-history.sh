#!/usr/bin/env bash
# Generate an Allure report with history for GitHub Pages.
# Replaces simple-elf/allure-report-action (Docker / public ECR) with a runner-local CLI.
# SUBFOLDER (optional) keeps the report and its history under gh-pages/<SUBFOLDER>/, so several
# suites can publish from one repository without overwriting each other.
set -euo pipefail

ALLURE_RESULTS="${ALLURE_RESULTS:?ALLURE_RESULTS is required}"
GH_PAGES="${GH_PAGES:?GH_PAGES is required}"
ALLURE_REPORT="${ALLURE_REPORT:-allure-report}"
ALLURE_HISTORY="${ALLURE_HISTORY:-allure-history}"
SUBFOLDER="${SUBFOLDER:-}"
KEEP_REPORTS="${KEEP_REPORTS:-20}"
GITHUB_RUN_NUM="${GITHUB_RUN_NUM:?GITHUB_RUN_NUM is required}"
GITHUB_RUN_ID="${GITHUB_RUN_ID:?GITHUB_RUN_ID is required}"
GITHUB_REPOSITORY="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
GITHUB_REPOSITORY_OWNER="${GITHUB_REPOSITORY_OWNER:?GITHUB_REPOSITORY_OWNER is required}"
GITHUB_SERVER_URL="${GITHUB_SERVER_URL:-https://github.com}"
REPORT_NAME="${REPORT_NAME:-Allure Report with history}"

REPOSITORY_NAME="${GITHUB_REPOSITORY##*/}"
GITHUB_PAGES_WEBSITE_URL="https://${GITHUB_REPOSITORY_OWNER}.github.io/${REPOSITORY_NAME}"

mkdir -p "./${GH_PAGES}" "./${ALLURE_HISTORY}" "./${ALLURE_RESULTS}"
# No `|| true`: the publish step deletes gh-pages runs missing from this copy, so a failed copy must stop here.
cp -R "./${GH_PAGES}/." "./${ALLURE_HISTORY}/"

if [[ -n "${SUBFOLDER}" ]]; then
  ALLURE_HISTORY="${ALLURE_HISTORY}/${SUBFOLDER}"
  GH_PAGES="${GH_PAGES}/${SUBFOLDER}"
  GITHUB_PAGES_WEBSITE_URL="${GITHUB_PAGES_WEBSITE_URL}/${SUBFOLDER}"
  mkdir -p "./${ALLURE_HISTORY}"
fi

echo "keep reports count ${KEEP_REPORTS}"
(
  cd "./${ALLURE_HISTORY}"
  rm -rf index.html last-history
  # Leave room for this run's report, which is (re)written below.
  mapfile -t REPORTS < <(ls 2>/dev/null | grep -E '^[0-9]+$' | grep -vx "${GITHUB_RUN_NUM}" | sort -n || true)
  if ((${#REPORTS[@]} >= KEEP_REPORTS)); then
    REMOVE_COUNT=$((${#REPORTS[@]} - KEEP_REPORTS + 1))
    echo "removing ${REMOVE_COUNT} old report(s)"
    rm -rf "${REPORTS[@]:0:REMOVE_COUNT}"
  fi
)

{
  echo "<!DOCTYPE html><meta charset=\"utf-8\"><meta http-equiv=\"refresh\" content=\"0; URL=${GITHUB_PAGES_WEBSITE_URL}/${GITHUB_RUN_NUM}/index.html\">"
  echo "<meta http-equiv=\"Pragma\" content=\"no-cache\"><meta http-equiv=\"Expires\" content=\"0\">"
} >"./${ALLURE_HISTORY}/index.html"

cat >"./${ALLURE_RESULTS}/executor.json" <<EOF
{
  "name": "GitHub Actions",
  "type": "github",
  "reportName": "${REPORT_NAME}",
  "url": "${GITHUB_PAGES_WEBSITE_URL}",
  "reportUrl": "${GITHUB_PAGES_WEBSITE_URL}/${GITHUB_RUN_NUM}",
  "buildUrl": "${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}",
  "buildName": "GitHub Actions Run #${GITHUB_RUN_ID}",
  "buildOrder": "${GITHUB_RUN_NUM}"
}
EOF

if [[ -d "./${GH_PAGES}/last-history" ]]; then
  echo "keep allure history from ${GH_PAGES}/last-history to ${ALLURE_RESULTS}/history"
  mkdir -p "./${ALLURE_RESULTS}/history"
  cp -R "./${GH_PAGES}/last-history/." "./${ALLURE_RESULTS}/history/"
fi

echo "generating report from ${ALLURE_RESULTS} to ${ALLURE_REPORT} ..."
allure generate --clean "./${ALLURE_RESULTS}" -o "./${ALLURE_REPORT}"

echo "copy allure-report to ${ALLURE_HISTORY}/${GITHUB_RUN_NUM}"
mkdir -p "./${ALLURE_HISTORY}/${GITHUB_RUN_NUM}"
cp -R "./${ALLURE_REPORT}/." "./${ALLURE_HISTORY}/${GITHUB_RUN_NUM}/"

if [[ -d "./${ALLURE_REPORT}/history" ]]; then
  echo "copy allure-report history to ${ALLURE_HISTORY}/last-history"
  mkdir -p "./${ALLURE_HISTORY}/last-history"
  cp -R "./${ALLURE_REPORT}/history/." "./${ALLURE_HISTORY}/last-history/"
fi
