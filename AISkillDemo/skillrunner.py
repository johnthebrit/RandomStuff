import os
import textwrap
import urllib.request
import xml.etree.ElementTree as ET

try:
    from openai import OpenAI
except ImportError:  # Optional dependency for the AI summary
    OpenAI = None


CHANNEL_ID = "UCpIn7ox7j7bH_OFj7tYouOQ"  # John Savill's Technical Training
RSS_FEED_URL = f"https://www.youtube.com/feeds/videos.xml?channel_id={CHANNEL_ID}"

endpoint = "https://foundryagentproject-resource.services.ai.azure.com/openai/v1"
deployment_name = "gpt-5.4-mini"


def _get_openai_client():
    api_key = os.getenv("AZURE_OPENAI_KEY")
    if not api_key or OpenAI is None:
        return None
    return OpenAI(base_url=endpoint, api_key=api_key)


def fetch_latest_videos_from_rss(feed_url: str, limit: int = 10):
    """Fetch and parse the YouTube channel RSS feed."""
    with urllib.request.urlopen(feed_url, timeout=20) as resp:
        xml_bytes = resp.read()

    root = ET.fromstring(xml_bytes)
    ns = {
        "atom": "http://www.w3.org/2005/Atom",
        "yt": "http://www.youtube.com/xml/schemas/2015",
        "media": "http://search.yahoo.com/mrss/",
    }

    videos = []
    for entry in root.findall("atom:entry", ns)[:limit]:
        title = (entry.findtext("atom:title", default="", namespaces=ns) or "").strip()
        published = (entry.findtext("atom:published", default="", namespaces=ns) or "").strip()
        video_id = (entry.findtext("yt:videoId", default="", namespaces=ns) or "").strip()
        description = (
            entry.findtext("media:group/media:description", default="", namespaces=ns) or ""
        ).strip()

        url = f"https://youtu.be/{video_id}" if video_id else ""
        if not url:
            link_el = entry.find("atom:link[@rel='alternate']", ns)
            if link_el is not None:
                url = (link_el.get("href") or "").strip()

        videos.append(
            {
                "title": title,
                "published": published[:10] if published else "",
                "url": url,
                "description": description,
            }
        )

    return videos


def format_videos_as_markdown_table(videos):
    lines = ["| # | Title | Published | Link |", "|---|-------|-----------|------|"]
    for idx, v in enumerate(videos, start=1):
        safe_title = (v.get("title") or "").replace("|", "\\|")
        published = v.get("published") or ""
        url = v.get("url") or ""
        lines.append(f"| {idx} | {safe_title} | {published} | {url} |")
    return "\n".join(lines)


def build_suggested_summary(videos):
    client = _get_openai_client()
    if client is None:
        return "(AI summary unavailable: set AZURE_OPENAI_KEY to enable.)"

    prompt = textwrap.dedent(
        """
        You are generating the "Suggested summary" for a table of the latest 10 videos from a YouTube channel.
        Write ONE short paragraph summarizing the themes across the videos.
        Don't invent topics that aren't implied by the titles/descriptions.
        """
    ).strip()

    # Keep the model input small but useful.
    compact = [
        {
            "title": v.get("title", ""),
            "description": (v.get("description", "") or "")[:240],
        }
        for v in videos
    ]

    completion = client.chat.completions.create(
        model=deployment_name,
        messages=[
            {"role": "user", "content": prompt},
            {"role": "user", "content": f"Videos (most recent first):\n{compact}"},
        ],
    )
    return (completion.choices[0].message.content or "").strip()


def run_demo():
    print("=== Get Latest Videos Demo ===")
    print(f"Channel ID: {CHANNEL_ID}")
    print(f"RSS: {RSS_FEED_URL}\n")

    print("Fetching latest videos...")
    videos = fetch_latest_videos_from_rss(RSS_FEED_URL, limit=10)

    if not videos:
        print("Could not retrieve the latest videos (RSS returned no entries).")
        return

    print("\n" + format_videos_as_markdown_table(videos) + "\n")
    print("## Suggested summary\n")
    print(build_suggested_summary(videos))


if __name__ == "__main__":
    run_demo()
