---
name: arcnode-map
description: Map this project as a mind map for ArcNode - what it is, what it is made of, how deep it goes, and how the parts connect. Use when asked to build, refresh or fix the ArcNode map, or when .arcnode/map.json is missing or stale.
---

# Mapping this project for ArcNode

You are drawing the whiteboard diagram a new engineer would want on their first
day. Not a file tree - the project's **meaning**.

Write your answer to `.arcnode/map.json`. That file is the only output. The
developer applies it with `arcnode audit`; you never write nodes yourself.

## How to write it

Everything you write lands in front of people who did not build this project -
a new joiner, a designer, someone's manager. Write for a smart person who is not
an expert in this codebase.

- **Plain words.** Say "the part that checks who you are" before "the auth
  middleware". Name the technology second, in brackets, if it helps.
- **No unexplained jargon or acronyms.** If a term is unavoidable, define it in
  the same sentence you first use it.
- **Short sentences.** One idea each.
- **Say what it is for, not how it is coded.** "Keeps two people from
  overwriting each other's edits", not "optimistic lock with TTL heartbeat".
- **Use bullets for anything with parts to it**, and a short paragraph for the
  one-line "what is this". `description` is the one-liner; `notes` is where
  bullets and detail go.
- **No marketing.** Plain and accurate beats impressive.

A useful test: would someone who has never opened this repository understand
what this part does, and why it exists, from your sentence alone?

## 1. Read the project

Run this for a compact skeleton - folder names, file names, the manifest and the
main docs, with build output and dependencies already stripped:

```
arcnode audit --evidence
```

That is the starting point, not the whole job. Open the READMEs, the entry
points, the route/table/command definitions - whatever it takes to answer "what
does this project actually do". Read enough to be sure; the map is worth more
than the tokens.

## 2. Decide what the concepts are

A concept is a **capability or a domain**, not a folder.

- "Billing & invoices", never `src/lib/billing`.
- Never use a path, a filename or an extension as a title.
- Merge folders that serve one idea into one concept. Split a folder that holds
  several unrelated ideas.
- Nest by meaning. A concept's parent is the larger part it belongs to, which is
  often **not** its parent directory.
- Leave out build output, dependencies, lockfiles, generated assets and config
  noise. If it does not change how someone understands the project, it is not a
  concept.

**There is no depth limit and no concept limit.** Go as deep as the project
really goes: a subsystem that genuinely has four levels of structure should have
four levels of nodes. Do not flatten a real hierarchy to keep the map small, and
do not pad a shallow one to make it look thorough. The shape should match the
project. A small tool might be 8 concepts two deep; a platform might be 60 across
five levels.

## 3. Give every concept its own identity

Each node carries five things beyond its title. A map where every node has the
same status, no category and no tags is a map that has thrown away most of what
ArcNode is for. Fill them in per concept - differences are the point.

### status — where this part actually stands

| status | means |
|---|---|
| `proposed` | discussed or planned, no code yet |
| `ready` | specified and agreed, ready to build |
| `built` | implemented and working |
| `verified` | implemented **and** covered by tests, or proven in production |
| `deprecated` | still present but on the way out; do not build on it |

Judge this from the repository, not from optimism: code with a passing test file
next to it is `verified`; code with no tests is `built`; a folder of specs with
no implementation is `proposed`. Default is `proposed` if you omit it.

### category — which kind of thing this is

One category per concept, chosen from a list you declare yourself in
`categories`. Pick 4-8 that carve *this* project up usefully, give each a hex
colour (they colour the node on the canvas) and optionally a
[lucide](https://lucide.dev) icon name. Typical sets: Frontend / Backend / Data /
Infrastructure / Tooling / Docs - but choose what fits what you actually read.

### tags — the cross-cutting facts

Many per concept, free-form, and they cut *across* the hierarchy - that is their
job. Good tags answer "show me everything that…": `security`, `public-api`,
`needs-tests`, `performance`, `external-service`, `deprecated-path`. Do not
re-tag what the category or the hierarchy already says.

### icon — a lucide icon name

Optional, e.g. `Database`, `ShieldCheck`, `Terminal`, `Palette`.

### notes — the detail that does not belong in the description

Optional and longer: caveats, gotchas, "this is the third attempt at X", the
thing you would tell someone before they touch it. `description` stays short.

## 4. Connect them

`links` are the cross-cutting edges - how the parts talk to each other. Never
restate a parent/child pair as a link; the nesting already says that.

**Prefer these eight shared relationship types.** They ship with ArcNode and
already carry inverse labels and colours, so a map that uses them reads
consistently against every other project:

| type | use when | inverse |
|---|---|---|
| `depends-on` | target must exist before source can be built | required-by |
| `blocks` | source prevents progress on target | blocked-by |
| `implements` | source realises the intent described by target | implemented-by |
| `supersedes` | source replaces target | superseded-by |
| `extends` | source adds to target without replacing it | extended-by |
| `triggers-on` | source runs in response to target | triggers |
| `risks` | source introduces risk to target | at-risk-from |
| `constrains` | source limits how target may be built | constrained-by |

Only invent a new type name when none of the eight honestly fits; it will be
created for this project alone.

`paths` anchor a concept to the real code, so someone can jump from the map to
the files. Use paths you actually saw. Omit rather than invent.

## 5. Write .arcnode/map.json

```json
{
  "summary": "Two or three sentences: what this project is and what it does.",
  "categories": [
    { "name": "Backend", "color_hex": "#7CA8E8", "icon": "Server" },
    { "name": "Data", "color_hex": "#7CC6A4", "icon": "Database" }
  ],
  "concepts": [
    {
      "key": "tree-engine",
      "title": "Tree engine",
      "description": "Keeps the tree in order: what sits under what, and what moves where.",
      "notes": "Every change to the tree goes through this one place, so the rules cannot drift apart.

- Decides the order items appear in
- Refuses moves that would make an item its own parent
- Shared by the website and the server, so both behave the same",
      "parent": null,
      "paths": ["src/engine"],
      "status": "verified",
      "category": "Backend",
      "tags": ["core", "pure"],
      "icon": "GitBranch"
    },
    {
      "key": "fractional-ordering",
      "title": "Fractional ordering",
      "description": "Lets two people add items to the same list at once without the order jumping around.",
      "parent": "tree-engine",
      "paths": ["src/engine/ordering.ts"],
      "status": "verified",
      "category": "Backend",
      "tags": ["concurrency"]
    }
  ],
  "links": [
    { "from": "http-api", "to": "tree-engine", "type": "depends-on" }
  ]
}
```

Field rules:

- `key` - short slug, unique, referenced by `parent` and by `links`.
- `parent` - another concept's `key`, or `null` for a top-level part. Nest as
  deep as the project does.
- `category` - must match a `name` in `categories`, or be omitted.
- `color_hex` - six-digit hex, e.g. `#7CA8E8`.

## 6. Hand it back

Tell the developer to review it and run:

```
arcnode audit --dry-run    # print what would change, write nothing
arcnode audit              # apply the map
arcnode audit --prune      # apply, and delete file/folder nodes left by old audits
```

Re-running is safe. A concept that already exists keeps its place; its status,
category, tags and icon are re-synced from the map, so fixing a status here and
re-running is the normal way to correct one. Nodes a human created by hand are
never touched.
