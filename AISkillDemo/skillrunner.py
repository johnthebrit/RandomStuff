import json
import os
import re
import sys
import urllib.request
from typing import Optional

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
    # Preserve both the beginning and end for better debugging context.
    # Keep ~70% head and ~30% tail (at least 200 chars if possible).
    head_len = max(200, int(limit * 0.7))
    tail_len = max(200, limit - head_len)
    if head_len + tail_len > limit:
        # In case min clamps overshoot.
        head_len = max(0, limit - tail_len)
    head = text[:head_len]
    tail = text[-tail_len:] if tail_len > 0 else ""
    return (
        head
        + f"\n\n... (truncated, {len(text)} chars total; showing head+tail) ...\n\n"
        + tail
    )


def _trace_enabled() -> bool:
    return ("--trace" in sys.argv) or (os.getenv("SKILL_TRACE") == "1")


def _trace_print(title: str, body: str = "", *, limit: int = 2000, color=None):
    if not _trace_enabled():
        return
    rule = "=" * 80
    dash = "-" * 80
    if color is None:
        print("\n" + rule)
        print(title)
    else:
        print("\n" + color(rule))
        print(color(title))
    if body:
        rendered = _truncate(body, limit)
        if color is None:
            print(dash)
            print(rendered)
        else:
            print(color(dash))
            print(color(rendered))


def _trace_messages(messages, *, limit: int = 2000):
    if not _trace_enabled():
        return

    # Print each message as its own section so truncation is per-message,
    # not across the whole combined transcript.
    _trace_print("REQUEST MESSAGES (per message)", color=_ansi_gray)
    for i, m in enumerate(messages):
        role = m.get("role")
        content = m.get("content") or ""
        suffix = ""
        if "tool_calls" in m:
            suffix += "\n(tool_calls present)"
        if "tool_call_id" in m:
            suffix += f"\n(tool_call_id={m['tool_call_id']})"
        _trace_print(f"[{i}] role={role}", content + suffix, limit=limit, color=_ansi_gray)


def _color_enabled() -> bool:
    # Respect the NO_COLOR convention. Also avoid emitting ANSI when redirected.
    if os.getenv("NO_COLOR") is not None:
        return False
    try:
        return sys.stdout.isatty()
    except Exception:
        return False


def _ansi_orange(text: str) -> str:
    if not _color_enabled():
        return text
    # 24-bit foreground: orange
    orange = "\x1b[38;2;255;165;0m"
    reset = "\x1b[0m"
    return f"{orange}{text}{reset}"


def _ansi_gray(text: str) -> str:
    if not _color_enabled():
        return text
    gray = "\x1b[38;2;180;180;180m"  # light gray
    reset = "\x1b[0m"
    return f"{gray}{text}{reset}"


def _ansi_lightblue(text: str) -> str:
    if not _color_enabled():
        return text
    blue = "\x1b[38;2;120;180;255m"  # light blue
    reset = "\x1b[0m"
    return f"{blue}{text}{reset}"


def _print_final_output(output: str):
    # Make the final output visually distinct from trace sections.
    header = "FINAL OUTPUT"
    rule = "=" * 80
    print("\n" + _ansi_orange(rule))
    print(_ansi_orange(header))
    print(_ansi_orange(rule))
    print(_ansi_orange(output.rstrip()) + "\n")


def tool_fetch_url(url: str, strip_media_descriptions: bool = False, max_chars: Optional[int] = None) -> str:
    req = urllib.request.Request(
        url,
        headers={"User-Agent": "AISkillDemo/skillrunner (python urllib)"},
        method="GET",
    )
    with urllib.request.urlopen(req, timeout=20) as resp:
        raw = resp.read()

    text = raw.decode("utf-8", errors="replace")

    # Optional size reduction while keeping XML valid:
    # Replace large <media:description>...</media:description> blocks with an empty element.
    if strip_media_descriptions:
        text = re.sub(
            r"<media:description\b[^>]*>.*?</media:description>",
            "<media:description/>",
            text,
            flags=re.DOTALL,
        )

    # Optional truncation (may make XML invalid). Only use if you know the returned slice is sufficient.
    if max_chars is not None and max_chars > 0 and len(text) > max_chars:
        text = text[:max_chars] + "\n<!-- TRUNCATED -->\n"

    return text


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
                    "strip_media_descriptions": {
                        "type": "boolean",
                        "description": "If true, replace <media:description> blocks with empty elements to reduce size.",
                        "default": False,
                    },
                    "max_chars": {
                        "type": "integer",
                        "description": "Optional max characters to return (may truncate and make XML invalid).",
                    },
                },
                "required": ["url"],
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
                "When you fetch an RSS feed, you must parse the XML yourself (there is no parsing tool).\n"
                "For YouTube RSS, prefer calling fetch_url with strip_media_descriptions=true to keep the XML smaller.\n"
                "Do not invent videos, dates, or links.\n"
                "When you use a skill, return output in the skill's required format."
            ),
        },
        {"role": "user", "content": user_request},
    ]

    tool_impl = {
        "list_skills": lambda args: tool_list_skills(),
        "get_skill_text": lambda args: tool_get_skill_text(args["skill_name"]),
        "fetch_url": lambda args: tool_fetch_url(
            args["url"],
            strip_media_descriptions=bool(args.get("strip_media_descriptions", False)),
            max_chars=args.get("max_chars"),
        ),
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

        _trace_print("MODEL RESPONSE (assistant.content)", msg.content or "", color=_ansi_lightblue)

        tool_calls = getattr(msg, "tool_calls", None)
        if tool_calls:
            if _trace_enabled():
                for tc in tool_calls:
                    _trace_print(
                        f"MODEL TOOL CALL -> {tc.function.name}",
                        f"arguments: {tc.function.arguments}",
                        limit=4000,
                        color=_ansi_lightblue,
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
                    _trace_print(f"TOOL RESULT <- {name}", preview, limit=2000, color=_ansi_gray)

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
    _print_final_output(output)


if __name__ == "__main__":
    run_demo()
