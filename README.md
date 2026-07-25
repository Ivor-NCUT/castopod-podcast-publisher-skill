# Castopod Podcast Publisher Skill

Publish local MP3/M4A audio, optional episode artwork, and Markdown Shownotes to Castopod from Codex. Castopod updates the podcast RSS feed, which subscribed platforms can then pull automatically.

The included `Dockerfile` inherits the official image and only enables the
Castopod REST API from `CP_REST_API_USERNAME` and
`CP_REST_API_PASSWORD`.

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

An installed copy may keep non-secret instance values in
`references/instance.md`; this path is ignored by Git. Keep the API password
in the system keychain.

The script creates a draft unless `--publish-now` or `--schedule` is supplied.

## Validate a feed before distribution

Podcast directories use the public owner email to verify control of a feed.
In Castopod, edit the podcast and disable “Remove the owner email from the
public RSS feed” before submitting the RSS URL.

```bash
python3 scripts/validate_rss.py \
  "https://example.zeabur.app/@show/feed.xml"
```

The validator has no third-party dependencies. It checks the owner email,
artwork, RSS episode metadata, enclosure MIME/length, and public byte-range
access.

## Files

- `SKILL.md`: Codex workflow and safety rules.
- `scripts/publish_episode.sh`: deterministic Castopod API publisher.
- `scripts/validate_rss.py`: RSS directory-compatibility validator.
- `agents/openai.yaml`: Codex UI metadata.
- `Dockerfile`: minimal Zeabur image with REST API configuration enabled.
