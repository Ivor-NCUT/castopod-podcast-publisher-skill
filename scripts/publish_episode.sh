#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  publish_episode.sh --audio FILE --shownotes FILE --title TITLE [options]

Options:
  --cover FILE
  --slug SLUG
  --type full|trailer|bonus
  --episode-number NUMBER
  --season-number NUMBER
  --publish-now
  --schedule "YYYY-MM-DD HH:MM"
  --timezone ZONE
  --dry-run
EOF
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

audio=
cover=
shownotes=
title=
slug=
episode_type=full
episode_number=
season_number=
publication=draft
schedule=
timezone=Asia/Shanghai
dry_run=false

while (($#)); do
  case "$1" in
    --audio) audio=${2-}; shift 2 ;;
    --cover) cover=${2-}; shift 2 ;;
    --shownotes) shownotes=${2-}; shift 2 ;;
    --title) title=${2-}; shift 2 ;;
    --slug) slug=${2-}; shift 2 ;;
    --type) episode_type=${2-}; shift 2 ;;
    --episode-number) episode_number=${2-}; shift 2 ;;
    --season-number) season_number=${2-}; shift 2 ;;
    --publish-now) publication=now; shift ;;
    --schedule) publication=schedule; schedule=${2-}; shift 2 ;;
    --timezone) timezone=${2-}; shift 2 ;;
    --dry-run) dry_run=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

[[ -f "$audio" ]] || die "audio file not found: $audio"
[[ -f "$shownotes" ]] || die "Shownotes file not found: $shownotes"
[[ -z "$cover" || -f "$cover" ]] || die "cover file not found: $cover"
[[ -n "$title" ]] || die "title is required"
[[ "$audio" =~ \.(mp3|m4a)$ ]] || die "audio must be MP3 or M4A"
[[ -z "$cover" || "$cover" =~ \.(jpg|jpeg|png)$ ]] || die "cover must be JPG, JPEG, or PNG"
[[ "$episode_type" =~ ^(full|trailer|bonus)$ ]] || die "type must be full, trailer, or bonus"
[[ "$publication" != schedule || "$schedule" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}$ ]] ||
  die "schedule must use YYYY-MM-DD HH:MM"

slug=${slug:-episode-$(date +%Y%m%d-%H%M%S)}

if [[ "$dry_run" == true ]]; then
  jq -n \
    --arg audio "$audio" \
    --arg cover "$cover" \
    --arg shownotes "$shownotes" \
    --arg title "$title" \
    --arg slug "$slug" \
    --arg publication "$publication" \
    '{dry_run:true,audio:$audio,cover:$cover,shownotes:$shownotes,title:$title,slug:$slug,publication:$publication}'
  exit 0
fi

for command in curl jq; do
  command -v "$command" >/dev/null || die "required command not found: $command"
done

: "${CASTOPOD_BASE_URL:?CASTOPOD_BASE_URL is required}"
: "${CASTOPOD_API_USERNAME:?CASTOPOD_API_USERNAME is required}"
: "${CASTOPOD_API_PASSWORD:?CASTOPOD_API_PASSWORD is required}"
: "${CASTOPOD_USER_ID:?CASTOPOD_USER_ID is required}"
: "${CASTOPOD_PODCAST_ID:?CASTOPOD_PODCAST_ID is required}"

base_url=${CASTOPOD_BASE_URL%/}
create_args=(
  --http1.1
  --silent --show-error --fail-with-body
  --user "${CASTOPOD_API_USERNAME}:${CASTOPOD_API_PASSWORD}"
  --request POST "${base_url}/api/rest/v1/episodes"
  --form "created_by=${CASTOPOD_USER_ID}"
  --form "updated_by=${CASTOPOD_USER_ID}"
  --form "podcast_id=${CASTOPOD_PODCAST_ID}"
  --form "title=${title}"
  --form "slug=${slug}"
  --form "type=${episode_type}"
  --form "audio_file=@${audio}"
  --form "description=<${shownotes}"
)

[[ -z "$cover" ]] || create_args+=(--form "cover=@${cover}")
[[ -z "$episode_number" ]] || create_args+=(--form "episode_number=${episode_number}")
[[ -z "$season_number" ]] || create_args+=(--form "season_number=${season_number}")

episode=$(curl "${create_args[@]}")
episode_id=$(jq -er '.id' <<<"$episode") || die "Castopod response did not contain an episode ID"

if [[ "$publication" == draft ]]; then
  jq -n --argjson episode_id "$episode_id" --arg status draft \
    '{episode_id:$episode_id,status:$status}'
  exit 0
fi

publish_args=(
  --http1.1
  --silent --show-error --fail-with-body
  --user "${CASTOPOD_API_USERNAME}:${CASTOPOD_API_PASSWORD}"
  --request POST "${base_url}/api/rest/v1/episodes/${episode_id}/publish"
  --form "created_by=${CASTOPOD_USER_ID}"
  --form "publication_method=${publication}"
  --form "client_timezone=${timezone}"
)
[[ "$publication" != schedule ]] || publish_args+=(--form "scheduled_publication_date=${schedule}")

published=$(curl "${publish_args[@]}")
jq -n \
  --argjson episode_id "$episode_id" \
  --arg status "$publication" \
  --argjson response "$published" \
  '{episode_id:$episode_id,status:$status,response:$response}'
