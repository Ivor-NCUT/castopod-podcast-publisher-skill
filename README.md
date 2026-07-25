# Castopod Podcast Publisher Skill

Publish local MP3/M4A audio, optional episode artwork, and Markdown Shownotes to Castopod from Codex. Castopod updates the podcast RSS feed, which subscribed platforms can then pull automatically.

## Install

```bash
npx skills add Ivor-NCUT/castopod-podcast-publisher-skill -g -y
```

## Configure

Set these values outside Git:

```bash
export CASTOPOD_BASE_URL="https://example.zeabur.app"
export CASTOPOD_API_USERNAME="codex-publisher"
export CASTOPOD_API_PASSWORD="..."
export CASTOPOD_USER_ID="1"
export CASTOPOD_PODCAST_ID="1"
```

The script creates a draft unless `--publish-now` or `--schedule` is supplied.

## Files

- `SKILL.md`: Codex workflow and safety rules.
- `scripts/publish_episode.sh`: deterministic Castopod API publisher.
- `agents/openai.yaml`: Codex UI metadata.
