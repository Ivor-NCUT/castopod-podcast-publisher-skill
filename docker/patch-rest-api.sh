#!/bin/sh
set -eu

target="${1:-/etc/s6-overlay/s6-rc.d/bootstrap/prepare-environment.sh}"
tmp="$(mktemp)"

grep -q '^# prevent .env from being writable$' "$target"

awk '
/^# prevent .env from being writable$/ {
  print "if [ -n \"${CP_REST_API_PASSWORD:-}\" ]; then"
  print "  cat >> \"$ENV_FILE_LOCATION\" << EOF"
  print ""
  print "restapi.enabled=true"
  print "restapi.basicAuth=true"
  print "restapi.basicAuthUsername=\"${CP_REST_API_USERNAME:-codex-publisher}\""
  print "restapi.basicAuthPassword=\"${CP_REST_API_PASSWORD}\""
  print "EOF"
  print "fi"
  print ""
}
{ print }
' "$target" > "$tmp"

cat "$tmp" > "$target"
rm "$tmp"
