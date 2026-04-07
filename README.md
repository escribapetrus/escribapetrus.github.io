# Blog

Personal blog powered by a custom Elixir static site generator.

## Quick Start

```bash
make build    # Generate site to docs/
make serve    # Build + serve at localhost:8000
```

## Writing Posts

Add markdown or org-mode files to `publish/`:

**Markdown** (`publish/my-post.md`):
```markdown
---
title: "My Post Title"
date: 2026-04-07
description: "A short description"
tags: [tag1, tag2]
---

Content goes here...
```

**Org-mode** (`publish/my-post.org`):
```org
#+TITLE: My Post Title
#+DATE: 2026-04-07
#+DESCRIPTION: A short description
#+TAGS: tag1, tag2

Content goes here...
```

## Structure

```
publish/          # Source files (md/org)
drafts/           # Work in progress (ignored)
docs/             # Generated HTML (GitHub Pages)
backup/           # Old site files
generator/blog/   # Elixir generator
config.yml        # Site configuration
```

## Configuration

Edit `config.yml`:

```yaml
title: "My Blog"
description: "A personal blog"
author: "Your Name"
url: "https://yourdomain.com"
```

## Deployment

Push to `master` → GitHub Actions builds → deploys to GitHub Pages.
