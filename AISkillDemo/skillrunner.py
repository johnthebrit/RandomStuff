import json
import os
import sys
import urllib.request
import xml.etree.ElementTree as ET

try:
    from openai import OpenAI
except ImportError:
    OpenAI = None


endpoint = "https://foundryagentproject-resource.services.ai.azure.com/openai/v1"
deployment_name = "gpt-5.4-mini"

SKILLS = {
    "get-latest-videos": {
        "path": os.path.join("skills", "get-latest-videos", "skill.md"),
        "summary": (
            "Retrieve the 10 most recent public videos from a YouTube channel using the public RSS feed "
            "and return a markdown table plus a short 'Suggested summary' paragraph."
        ),
    }
}


def _get_openai_client():
    api_key = os.getenv("AZURE_OPENAI_KEY")
    if not api_key:
        return None
    if OpenAI is None:
        return None
    return OpenAI(base_url=endpoint, api_key=api_key)


def _missing_requirements_message() -> str:
    missing = []
    if OpenAI is None:
        missing.append("Python package 'openai'")
    if not os.getenv("AZURE_OPENAI_KEY"):
        missing.append("environment variable AZURE_OPENAI_KEY")
    if not missing:
        return ""

    lines = [
        "Missing requirements for tool-driven execution:",
        "- " + "\n- ".join(missing),
        "",
        "Fix:",
        "- Install package: python -m pip install openai",
        "- Set key in this shell (PowerShell): $env:AZURE_OPENAI_KEY = '<your key>'",
    ]
    return "\n".join(lines)


def load_skill_text(path: str) -> str:
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def _truncate(text: str, limit: int) -> str:
    if text is None:
        return ""
    if len(text) <= limit:
        return text
    return text[:limit] + f"\n... (truncated, {len(text)} chars total)"


def _trace_enabled() -> bool:
    return ("--trace" in sys.argv) or (os.getenv("SKILL_TRACE") == "1")


def _trace_print(title: str, body: str = "", *, limit: int = 2000):
    if not _trace_enabled():
        return
    print("\n" + "=" * 80)
    print(title)
    if body:
        print("-" * 80)
        print(_truncate(body, limit))


def _trace_messages(messages, *, limit: int = 2000):
    if not _trace_enabled():
        return
    printable = []
    for i, m in enumerate(messages):
        role = m.get("role")
        content = m.get("content")
        if content is None:
            content = ""
        entry = f"[{i}] role={role}\n{content}"
        if "tool_calls" in m:
            entry += "\n(tool_calls present)"
        if "tool_call_id" in m:
            entry += f"\n(tool_call_id={m['tool_call_id']})"
        printable.append(entry)
    _trace_print("REQUEST MESSAGES", "\n\n".join(printable), limit=limit)


def tool_fetch_url(url: str) -> str:
    req = urllib.request.Request(
        url,
        headers={
            "User-Agent": "AISkillDemo/skillrunner (python urllib)"
        },
        method="GET",
    )
    with urllib.request.urlopen(req, timeout=20) as resp:
        raw = resp.read()
    return raw.decode("utf-8", errors="replace")


def tool_parse_youtube_rss(xml_text: str, limit: int = 10):
    """Parse YouTube channel RSS feed XML into a compact list of videos."""
    root = ET.fromstring(xml_text)
    ns = {
        "atom": "http://www.w3.org/2005/Atom",
        "yt": "http://www.youtube.com/xml/schemas/2015",
        "media": "http://search.yahoo.com/mrss/",
    }

    videos = []
    for entry in root.findall("atom:entry", ns)[:limit]:
        title = (entry.findtext("atom:title", default="", namespaces=ns) or "").strip()
        published_full = (entry.findtext("atom:published", default="", namespaces=ns) or "").strip()
        published = published_full[:10] if published_full else ""
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
                "published": published,
                "url": url,
                "description": description,
            }
        )

    return videos


def tool_list_skills():
    return [{"name": name, "summary": meta["summary"]} for name, meta in SKILLS.items()]


def tool_get_skill_text(skill_name: str) -> str:
    if skill_name not in SKILLS:
        raise ValueError(f"Unknown skill: {skill_name}")
    return load_skill_text(SKILLS[skill_name]["path"])


TOOLS = [
    {
        "type": "function",
        "function": {
            "name": "list_skills",
            "description": "List available skills (name + short summary).",
            "parameters": {
                "type": "object",
                "properties": {},
                "additionalProperties": False,
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_skill_text",
            "description": "Get the full text of a skill by name.",
            "parameters": {
                "type": "object",
                "properties": {
                    "skill_name": {"type": "string", "description": "The skill name to load."},
                },
                "required": ["skill_name"],
                "additionalProperties": False,
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "fetch_url",
            "description": "Fetch a URL and return the response body as UTF-8 text.",
            "parameters": {
                "type": "object",
                "properties": {
                    "url": {"type": "string", "description": "The URL to fetch."},
                },
                "required": ["url"],
                "additionalProperties": False,
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "parse_youtube_rss",
            "description": "Parse a YouTube RSS feed XML string and return up to N videos.",
            "parameters": {
                "type": "object",
                "properties": {
                    "xml_text": {"type": "string", "description": "RSS feed XML."},
                    "limit": {"type": "integer", "description": "Max entries to return.", "default": 10},
                },
                "required": ["xml_text"],
                "additionalProperties": False,
            },
        },
    },
]


def run_skill_with_tools(user_request: str) -> str:
    client = _get_openai_client()
    if client is None:
        raise RuntimeError(_missing_requirements_message() or "Missing requirements.")

    messages = [
        {
            "role": "system",
            "content": (
                "You are a helpful assistant with access to tools.\n"
                "If the user's request can be fulfilled by an available skill, you should CHOOSE to use it:\n"
                "- First call list_skills to discover what skills exist.\n"
                "- If a skill is relevant, call get_skill_text(skill_name) to retrieve the full instructions.\n"
                "- Then follow that skill's steps exactly.\n"
                "You can only fetch live web data using the provided tools (e.g., fetch_url).\n"
                "Do not invent videos, dates, or links.\n"
                "When you use a skill, return output in the skill's required format."
            ),
        },
        {"role": "user", "content": user_request},
    ]

    tool_impl = {
        "list_skills": lambda args: tool_list_skills(),
        "get_skill_text": lambda args: tool_get_skill_text(args["skill_name"]),
        "fetch_url": lambda args: tool_fetch_url(args["url"]),
        "parse_youtube_rss": lambda args: tool_parse_youtube_rss(args["xml_text"], int(args.get("limit", 10))),
    }

    for _ in range(16):
        _trace_messages(messages)
        try:
            resp = client.chat.completions.create(
                model=deployment_name,
                messages=messages,
                tools=TOOLS,
                tool_choice="auto",
            )
        except TypeError as e:
            raise RuntimeError(
                "Your OpenAI client library may not support tool calling (missing 'tools' argument support). "
                "Try upgrading: python -m pip install --upgrade openai"
            ) from e
        except Exception as e:
            raise RuntimeError(
                "Model call failed. If you're using an Azure/Foundry endpoint, confirm this deployment supports tool calling/function calling. "
                "If it doesn't, option-3 execution can't run as-is."
            ) from e
        msg = resp.choices[0].message

        _trace_print("MODEL RESPONSE (assistant.content)", msg.content or "")

        tool_calls = getattr(msg, "tool_calls", None)
        if tool_calls:
            if _trace_enabled():
                for tc in tool_calls:
                    _trace_print(
                        f"MODEL TOOL CALL -> {tc.function.name}",
                        f"arguments: {tc.function.arguments}",
                        limit=4000,
                    )

            # Record the assistant message that requested tool calls.
            messages.append(
                {
                    "role": "assistant",
                    "content": msg.content or "",
                    "tool_calls": [
                        {
                            "id": tc.id,
                            "type": "function",
                            "function": {
                                "name": tc.function.name,
                                "arguments": tc.function.arguments,
                            },
                        }
                        for tc in tool_calls
                    ],
                }
            )

            for tc in tool_calls:
                name = tc.function.name
                if name not in tool_impl:
                    raise RuntimeError(f"Model requested unknown tool: {name}")

                args = json.loads(tc.function.arguments or "{}")
                result = tool_impl[name](args)

                if _trace_enabled():
                    # Avoid printing enormous RSS XML/tool output; trim for readability.
                    if isinstance(result, str):
                        preview = result
                    else:
                        preview = json.dumps(result, ensure_ascii=False)
                    _trace_print(f"TOOL RESULT <- {name}", preview, limit=2000)

                messages.append(
                    {
                        "role": "tool",
                        "tool_call_id": tc.id,
                        "content": json.dumps(result, ensure_ascii=False),
                    }
                )

            continue

        return (msg.content or "").strip()

    raise RuntimeError("Tool-call loop exceeded maximum iterations.")


def run_demo():
    print("=== Skill Runner (Tool-Driven) Demo ===")
    if _trace_enabled():
        print("Trace mode: ON (shows prompts, tool calls, tool results)")
    else:
        print("Trace mode: OFF (add --trace or set SKILL_TRACE=1)")

    # Generic user request; the model must discover and choose a skill.
    user_request = "show me my latest youtube videos"

    output = run_skill_with_tools(user_request)
    print(output)


if __name__ == "__main__":
    run_demo()
