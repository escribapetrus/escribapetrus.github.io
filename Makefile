.PHONY: build clean serve help compile test

GENERATOR_DIR := generator/blogcpp
BIN           := $(GENERATOR_DIR)/blog

help:
	@echo "Blog Generator - Available commands:"
	@echo "  make build   - Generate the static site"
	@echo "  make serve   - Build and serve locally (port 8000)"
	@echo "  make clean   - Remove generated files"
	@echo "  make test    - Run tests"

compile:
	$(MAKE) -C $(GENERATOR_DIR)

build: compile
	$(BIN) --config config.yml --source publish --output docs

serve: build
	@echo "Serving at http://localhost:8000"
	@cd docs && python3 -m http.server 8000

test:
	$(MAKE) -C generator/blog test

clean:
	rm -rf docs/*
	$(MAKE) -C $(GENERATOR_DIR) clean
	@echo "Cleaned"
