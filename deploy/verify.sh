#!/bin/bash
set -e

TARGET_IP=$1
if [ -z "$TARGET_IP" ]; then
  echo "Error: TARGET_IP secret is not set."
  exit 1
fi

HTTP_TARGET="http://${TARGET_IP}"

PASS=0
FAIL=0

check_pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
check_fail() { echo "FAIL: $1"; FAIL=$((FAIL + 1)); }

http_status() {
  curl -s -o /dev/null -w "%{http_code}" \
    --max-time 10 \
    "${@:2}" \
    "$1" || echo "000"
}

echo " Verification: ${HTTP_TARGET}"
echo "- HTTP checks via nginx -"

STATUS=$(http_status "${HTTP_TARGET}/" -H "Accept: text/html")
if [ "$STATUS" -eq 200 ]; then
  check_pass "GET / (Accept: text/html) -> 200"
else
  check_fail "GET / (Accept: text/html) -> expected 200, got ${STATUS}"
fi

STATUS=$(http_status "${HTTP_TARGET}/" -H "Accept: application/json")
if [ "$STATUS" -eq 406 ]; then
  check_pass "GET / (Accept: application/json) -> 406"
else
  check_fail "GET / (Accept: application/json) -> expected 406, got ${STATUS}"
fi

STATUS=$(http_status "${HTTP_TARGET}/health/alive")
if [ "$STATUS" -eq 404 ]; then
  check_pass "GET /health/alive -> 404 (nginx deny)"
else
  check_fail "GET /health/alive -> expected 404 (nginx deny), got ${STATUS}"
fi

STATUS=$(http_status "${HTTP_TARGET}/health/ready")
if [ "$STATUS" -eq 404 ]; then
  check_pass "GET /health/ready -> 404 (nginx deny)"
else
  check_fail "GET /health/ready -> expected 404 (nginx deny), got ${STATUS}"
fi

STATUS=$(http_status "${HTTP_TARGET}/tasks" -H "Accept: application/json")
if [ "$STATUS" -eq 200 ]; then
  check_pass "GET /tasks (Accept: application/json) -> 200"
else
  check_fail "GET /tasks (Accept: application/json) -> expected 200, got ${STATUS}"
fi

STATUS=$(http_status "${HTTP_TARGET}/definitely-not-exists" -H "Accept: text/html")
if [ "$STATUS" -eq 404 ]; then
  check_pass "GET /definitely-not-exists (Accept: text/html) -> 404 (Not Found)"
else
  check_fail "GET /definitely-not-exists (Accept: text/html) -> expected 404, got ${STATUS}"
fi

echo "--------------------------------------"
echo " Results: ${PASS} passed, ${FAIL} failed"
if [ "$FAIL" -gt 0 ]; then
  echo "Verification failed! Pipeline stopped."
  exit 1
fi

echo "All tests passed!"
exit 0