# Blog

Personal blog powered by a custom C++ static site generator.

## Requirements

- C++17 compiler
- [cmark](https://github.com/commonmark/cmark) (`brew install cmark` on macOS, `apt install libcmark-dev` on Ubuntu)

## Quick Start

```bash
make build    # Compile generator + generate site to docs/
make serve    # Build + serve at localhost:8000
make test     # Run tests
make clean    # Remove generated files and build artifacts
```

## Writing Posts

Add markdown files to `publish/`:

```markdown
---
title: "My Post Title"
date: 2026-04-07
description: "A short description"
tags: [tag1, tag2]
---

Content goes here...
```

## Structure

```
publish/       # Source markdown files
docs/          # Generated HTML (GitHub Pages)
src/           # C++ generator source
config.yml     # Site configuration
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
