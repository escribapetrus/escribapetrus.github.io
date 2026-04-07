.PHONY: build clean serve deps help setup test

GENERATOR_DIR := generator/blog

help:
	@echo "Blog Generator - Available commands:"
	@echo "  make setup   - Install Elixir dependencies"
	@echo "  make build   - Generate the static site"
	@echo "  make serve   - Build and serve locally (port 8000)"
	@echo "  make clean   - Remove generated files"
	@echo "  make test    - Run tests"
	@echo "  make deps    - Update dependencies"

setup:
	cd $(GENERATOR_DIR) && mix deps.get

deps:
	cd $(GENERATOR_DIR) && mix deps.update --all

test: setup
	cd $(GENERATOR_DIR) && mix test

build: setup
	cd $(GENERATOR_DIR) && mix run -e "Blog.build(config: \"../../config.yml\", source_dir: \"../../publish\", output_dir: \"../../docs\")"

serve: build
	@echo "Serving at http://localhost:8000"
	@cd docs && python3 -m http.server 8000

clean:
	rm -rf docs/*
	@echo "Cleaned docs/"

escript: setup
	cd $(GENERATOR_DIR) && mix escript.build
	mv $(GENERATOR_DIR)/blog ./blog
	@echo "Built ./blog executable"
