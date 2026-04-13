# LF2B Architecture Decisions

> Record significant design decisions here as they are made.
> Format: Date — Decision — Rationale

---

## 2026-04-13 — Karpathy three-layer model adopted as core architecture

**Decision:** Raw sources (immutable) → Wiki (LLM-owned) → Query. No RAG vector pipeline in v0.1.

**Rationale:** Traditional RAG requires chunking, embedding, and vector search infrastructure. Karpathy's LLM Wiki pattern trades that complexity for a persistent, human-readable, markdown knowledge base that the LLM maintains incrementally. Cheaper to operate, easier to inspect, more portable. Vector search can be added later as an optional index layer, not a dependency.

---

## 2026-04-13 — Plain markdown as the canonical format

**Decision:** All wiki pages are plain markdown with YAML frontmatter. No database, no proprietary encoding.

**Rationale:** Survives any tool change. Readable without any software. Git-diffable. Obsidian, VS Code, any editor works. If LF2B tooling disappears, the knowledge base remains intact and queryable by grep.

---

## 2026-04-13 — Ollama as default LLM provider, cloud as opt-in

**Decision:** Local Ollama is the default. Cloud providers (Claude, GPT-4, Gemini) are opt-in via config.

**Rationale:** JP's sovereignty constraint. Knowledge about his life and thinking should not flow through vendor APIs by default. Local LLMs are sufficient for most ingestion and query tasks. Cloud LLMs are available for complex synthesis tasks the user explicitly chooses to delegate.

---

## 2026-04-13 — raw/ is gitignored by default

**Decision:** `raw/` is excluded from git commits by default. Wiki is committed.

**Rationale:** Raw sources may contain personal, sensitive, or copyrighted material. The wiki — being AI-synthesized — can be designed to be shareable. Users who want to commit raw sources can remove the gitignore entry explicitly.
