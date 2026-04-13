# LegionForge SecondBrain (LF2B)

> A sovereign, portable, AI-augmented second brain — local-first, brand-independent, and built on open standards.

**LegionForge** | [jp@legionforge.org](mailto:jp@legionforge.org) | [github.com/LegionForge](https://github.com/LegionForge)

---

## What Is This?

LF2B is a personal knowledge management system that turns raw information you consume — articles, videos, PDFs, notes, conversations — into a self-maintaining, queryable wiki. It compounds over time. The AI acts as librarian, not search engine.

The core design constraints:

- **Sovereign** — your data lives on your hardware, in plain markdown. No vendor can take it from you.
- **Portable** — flat files, Git-versioned, readable by any editor. No proprietary database.
- **Non-brand-dependent** — works with local LLMs (Ollama, LM Studio) or any cloud LLM. Swap the model without losing your knowledge base.
- **Distributed** — sync via Git, Syncthing, or any file-sync protocol you trust. No central server required.
- **Secure** — local-first means your private knowledge never touches a vendor's training pipeline.
- **Human-readable** — if all the AI tooling disappeared tomorrow, your wiki is still valid markdown.

---

## Inspiration & Credits

This project is directly inspired by the following creators and their work:

### Videos That Started This

| Video | Creator | Channel |
|-------|---------|---------|
| [Obsidian + Claude Code: The Second Brain Setup That Actually Works](https://www.youtube.com/watch?v=Y2rpFa43jTo) | Eric Tech | [@EricWTech](https://www.youtube.com/@EricWTech) |
| [Claude Code Turned Obsidian Into My Dream Second Brain](https://www.youtube.com/watch?v=2kbINqpluM0) | Mark Kashef | [@Mark_Kashef](https://www.youtube.com/@Mark_Kashef) |
| [Why 2026 Is the Year to Build a Second Brain (And Why You NEED One)](https://www.youtube.com/watch?v=0TpON5T-Sw4) | Nate B Jones | [@NateBJones](https://www.youtube.com/@NateBJones) |

### Foundational Concepts

- **Andrej Karpathy** — [LLM Wiki Gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f): The "AI as librarian" pattern that makes persistent wikis practical. Three-layer architecture (raw sources → wiki → schema) is the intellectual foundation of LF2B.
- **Tiago Forte** — [Building a Second Brain](https://fortelabs.com) / [PARA Method](https://fortelabs.com/blog/para): The PKM philosophy and organizational vocabulary behind second brains as a concept.
- **Vannevar Bush** — *As We May Think* (1945): The Memex — the original vision of associative knowledge stores that LLMs finally make real.

### Projects Studied & Synthesized

| Project | What it contributes |
|---------|-------------------|
| [Khoj](https://github.com/khoj-ai/khoj) | Self-hostable AI agent, multi-LLM, multi-platform access, AGPL |
| [COG-second-brain](https://github.com/huytieu/COG-second-brain) | Cognition + Obsidian + Git self-evolving cycle (daily/weekly/monthly) |
| [obsidian-second-brain](https://github.com/eugeniughelbur/obsidian-second-brain) | Claude Code skill framework, bi-temporal facts, scheduled agents |
| [raold/second-brain](https://github.com/raold/second-brain) | 100% local, pgvector, multimodal (CLIP + LLaVA), no API keys |
| [NicholasSpisak/second-brain](https://github.com/NicholasSpisak/second-brain) | Karpathy LLM Wiki implemented for Obsidian |
| [flepied/second-brain-agent](https://github.com/flepied/second-brain-agent) | Agent-based knowledge ingestion |

---

## Architecture

```
LF2B/
├── raw/              # Immutable source material (articles, PDFs, clips, notes)
│   ├── articles/
│   ├── videos/
│   ├── pdfs/
│   └── notes/
├── wiki/             # LLM-maintained knowledge base (AI writes, human reads)
│   ├── _index.md     # Master catalog of all wiki pages
│   ├── concepts/     # Concept definitions and summaries
│   ├── entities/     # People, projects, orgs, tools
│   ├── topics/       # Domain knowledge pages
│   └── syntheses/    # Cross-domain connections and insights
├── src/              # LF2B tooling
│   ├── core/         # Config, LLM provider abstraction
│   ├── ingest/       # Raw source processing pipeline
│   ├── wiki/         # Wiki maintenance (update, lint, cross-reference)
│   ├── query/        # Query interface
│   └── agents/       # Scheduled autonomous agents
├── scripts/          # Standalone utilities
├── tests/            # Test suite
├── docs/             # Architecture decisions, setup guides
└── CLAUDE.md         # LF2B schema and AI operating instructions
```

### Three-Layer Model (Karpathy Pattern)

```
RAW SOURCES  →  [AI Ingestion]  →  WIKI  →  [AI Query]  →  ANSWERS
(immutable)                      (LLM-owned)
```

The human curates what goes into `raw/`. The AI maintains everything in `wiki/`. The human asks questions. The AI files valuable answers back as new wiki pages.

---

## LLM Provider Strategy

LF2B is LLM-agnostic by design. Providers are swappable via config:

| Tier | Provider | Use case |
|------|---------|----------|
| Local (preferred) | Ollama, LM Studio | Daily ingestion, offline use |
| Local + GPU | LLaVA, CLIP | Multimodal (image/video content) |
| Cloud (optional) | Claude, GPT-4, Gemini | Complex synthesis, first-run wiki seeding |

**Default target:** Ollama on local hardware. Cloud LLMs are opt-in, never required.

---

## Sync & Distribution

| Method | Use case |
|--------|----------|
| Git | Version control, audit trail, rollback |
| Syncthing | LAN sync between personal machines, no cloud |
| Obsidian Sync | Optional cloud sync (vault-level encryption) |
| rclone | Encrypted backup to S3-compatible storage |

Plain markdown means any of these can be removed or replaced without data loss.

---

## How It Differs From Existing Tools

| Feature | LF2B | Notion | Obsidian Sync | Khoj | raold/second-brain |
|---------|------|--------|---------------|------|-------------------|
| Local-first | ✅ | ❌ | ✅ | ✅ | ✅ |
| LLM-agnostic | ✅ | ❌ | ❌ | ✅ | ✅ |
| Plain markdown | ✅ | ❌ | ✅ | ✅ | ❌ |
| Git-versioned wiki | ✅ | ❌ | ❌ | ❌ | ❌ |
| Distributed sync | ✅ | ❌ | cloud only | ❌ | ❌ |
| No API key required | ✅ | ❌ | ❌ | ✅ | ✅ |
| Multimodal | planned | ✅ | ❌ | partial | ✅ |
| Self-evolving agents | planned | ❌ | ❌ | ✅ | ❌ |

---

## Roadmap

### v0.1 — Foundation
- [ ] LLM provider abstraction (Ollama first)
- [ ] Ingest pipeline: markdown/text files → wiki
- [ ] `/wiki-init`, `/wiki-ingest`, `/wiki-query`, `/wiki-lint` commands
- [ ] CLAUDE.md schema (operating instructions for AI agents)

### v0.2 — Multimodal
- [ ] PDF ingest
- [ ] YouTube transcript ingest
- [ ] Web clipper integration

### v0.3 — Agents
- [ ] Scheduled daily capture agent
- [ ] Weekly synthesis agent
- [ ] Contradiction detection

### v0.4 — Distribution
- [ ] Git-based sync protocol
- [ ] Syncthing integration guide
- [ ] Multi-machine wiki merge

### v1.0 — Sovereign Stack
- [ ] Zero-cloud operation validated
- [ ] Full multimodal (images, audio)
- [ ] Public release + documentation

---

## Getting Started

> Setup guide coming in v0.1. For now, explore the `docs/` directory.

**Prerequisites:**
- [Ollama](https://ollama.com) (local LLM runtime)
- [Obsidian](https://obsidian.md) (optional but recommended vault UI)
- Python 3.11+
- Git

---

## Contributing

LF2B is part of the [LegionForge](https://github.com/LegionForge) open-source ecosystem. Contributions welcome — see `docs/CONTRIBUTING.md` (coming in v0.1).

The design philosophy: build for the person who wants complete sovereignty over their knowledge, not for the person who wants the easiest onboarding. Good defaults exist; forced cloud does not.

---

## License

MIT — your knowledge, your terms.

---

*LegionForge SecondBrain is built on the shoulders of Karpathy's LLM Wiki, Tiago Forte's PARA methodology, and the open-source PKM community. This project exists to make sovereign, compound knowledge management accessible without requiring trust in any vendor's continued existence.*
