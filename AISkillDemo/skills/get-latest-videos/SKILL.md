---
name: get-latest-videos
description: Retrieve the 10 most recent public videos from John Savill's Technical Training via the public YouTube RSS feed and return them as a markdown table plus a short "Suggested summary" paragraph. Use when the user asks for the latest/newest/recent YouTube videos or uploads from John Savill's Technical Training / @NTFAQGuy.
compatibility: Requires internet access to https://www.youtube.com/feeds/videos.xml
---

# YouTube Recent Videos Skill

## Purpose
Use this skill when the user asks for the latest or most recent videos from John Savill's Technical Training YouTube channel.

## What this skill does
Retrieve the 10 most recent public videos from the YouTube channel and return them in a clean summary.

## Data source
Use the public YouTube RSS feed to retrieve the latest videos (no API key required). If the RSS feed cannot be accessed and you have an authenticated YouTube Data API client available, use the Data API; otherwise, state that the latest videos could not be retrieved.

Channel name: John Savill's Technical Training
Channel URL: https://www.youtube.com/@NTFAQGuy

Channel ID: UCpIn7ox7j7bH_OFj7tYouOQ
RSS feed: https://www.youtube.com/feeds/videos.xml?channel_id=UCpIn7ox7j7bH_OFj7tYouOQ

Prefer official YouTube-provided sources (RSS or Data API) over third-party mirrors.

## Steps
1. Find the channel's latest public uploads.
2. Select the 10 most recent videos.
3. For each video, capture:
   - Title
   - Published date
   - URL
   - Description (if present in the source)
4. Sort newest to oldest.
5. Do not invent videos or dates.
6. If the source is unavailable, explain that the latest videos could not be retrieved.

## Output format

Return:

| # | Title | Published | Link |
|---|-------|-----------|------|

Then add:

## Suggested summary

A short paragraph summarizing the themes across the latest 10 videos.