---
name: castopod-podcast-publisher
description: Publish local MP3 or M4A podcast episodes to a Castopod instance from Codex, including episode artwork, Markdown Shownotes, episode metadata, drafts, immediate publishing, and scheduled publishing. Use when the user asks to upload, publish, schedule, or distribute a podcast through Castopod or its RSS feed.
---

# Castopod Podcast Publisher

Publish once to Castopod, then let podcast platforms pull the updated RSS feed.

## Workflow

1. Locate the audio, optional square cover, and Markdown Shownotes.
2. Confirm title, episode type, and whether the user wants a draft, immediate publication, or a schedule.
3. Read connection values from environment variables. Never place passwords in commands, logs, skill files, Git, or final responses.
4. Run `scripts/publish_episode.sh`.
5. Return the episode ID and Castopod response. Retrieve the podcast `feed_url` from `GET /api/rest/v1/podcasts/{id}` when the user needs the RSS address.
6. Verify the public episode or RSS URL after publication.

## Required environment

```bash
export CASTOPOD_BASE_URL="https://example.zeabur.app"
export CASTOPOD_API_USERNAME="codex-publisher"
export CASTOPOD_API_PASSWORD="..."
export CASTOPOD_USER_ID="1"
export CASTOPOD_PODCAST_ID="1"
```

Store secrets in the system keychain or a local ignored environment file. Do not commit them.

## Publish

Create a draft by default:

```bash
bash scripts/publish_episode.sh \
  --audio "/absolute/episode.m4a" \
  --cover "/absolute/cover.png" \
  --shownotes "/absolute/shownotes.md" \
  --title "Episode title"
```

Publish immediately only when explicitly requested:

```bash
bash scripts/publish_episode.sh \
  --audio "/absolute/episode.m4a" \
  --cover "/absolute/cover.png" \
  --shownotes "/absolute/shownotes.md" \
  --title "Episode title" \
  --publish-now
```

Schedule in the timezone supplied to the script:

```bash
bash scripts/publish_episode.sh \
  --audio "/absolute/episode.m4a" \
  --shownotes "/absolute/shownotes.md" \
  --title "Episode title" \
  --schedule "2026-07-26 09:00" \
  --timezone "Asia/Shanghai"
```

Use `--dry-run` to validate inputs without uploading.

## Boundaries

- Treat publishing as an external write. Default to a draft when intent is ambiguous.
- Do not upload the same episode separately to every platform. Submit the Castopod RSS feed once to each platform, then publish only through Castopod.
- Do not change, delete, or republish existing episodes unless the user explicitly requests it.
- Castopod accepts MP3/M4A audio, JPG/JPEG/PNG covers, Markdown Shownotes, VTT/SRT transcripts, and JSON chapters. This script intentionally covers the current audio, cover, and Shownotes workflow only.
