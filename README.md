# common

Claude Code plugin. One question, several Claude subagents each answering from
a different role, then a synthesis of where they diverge. No API keys, no
external providers — runs on your Claude Code subscription.

Also the home for shared skills: one directory per skill under `skills/`.

| Skill | Invoke | What |
|---|---|---|
| judge | `/common:judge "question"` | Role-scoped Claude panel + synthesis + HTML report |
| context-init | `/common:context-init` | Plant the context/loop discipline pointer in the project's `.claude/CLAUDE.md` (once per project) |
| context-engineering | auto (or by name) | Where information lives: context window vs disk |
| loop-engineering | auto (or by name) | Supervisor cycle for multi-session work, state in `.claude/state/` |

`context-*` and `loop-engineering` are imported verbatim from
[zkfmapf123/context_skills](https://github.com/zkfmapf123/context_skills); see that
README for the full walkthrough.

## Usage

```
/common:judge "Should I use UUID or BIGINT primary keys?"
/common:judge --roles=security,devil,simplicity "..."
/common:judge --model=opus --roles=architecture --no-artifact "..."
```

Flow: model → lenses (numbered menu, presets or `1,3,8`) → one round of
clarifying questions for anything the answer hinges on → members run in
parallel → one line per member + synthesis in chat → `.claude/council-cache/judge-<ts>.md`
and a shareable HTML report (`--no-artifact` to skip).

Roles (16) and presets (7): `config/roles.json`. Each role has a focus list, an ignore list, and the reason the lens exists — the shape the Claude subagent docs recommend for parallel reviewers.

## Install

Persistent, from a local clone or the GitHub repo:

```
/plugin marketplace add /path/to/common      # or: /plugin marketplace add <owner>/<repo>
/plugin install common@common
```

One-off, without installing:

```
claude --plugin-dir /path/to/common
```

## Layout

```
.claude-plugin/plugin.json   manifest
commands/<name>.md           one slash command: /common:<name>
skills/<name>/SKILL.md       one skill, plus any supporting files beside it
config/                      shared data (roles.json)
```

## Adding a skill

1. `mkdir skills/<name>` and write `skills/<name>/SKILL.md` with frontmatter:

   ```
   ---
   name: <name>
   description: When to use it. Claude reads this to decide whether to invoke.
   ---
   ```

2. Optional: `commands/<name>.md` with a `description`, `argument-hint`, and
   `allowed-tools` frontmatter, if the skill should be a slash command.
3. Reference plugin files as `${CLAUDE_PLUGIN_ROOT}/...`.
