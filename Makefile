.PHONY: build clean serve help test

CXX      := c++
CXXFLAGS := -std=c++17 -Wall -Wextra -O2
CMARK    := $(shell brew --prefix cmark 2>/dev/null)
CPPFLAGS := $(if $(CMARK),-I$(CMARK)/include)
LDFLAGS  := $(if $(CMARK),-L$(CMARK)/lib) -lcmark

SRC_DIR := src
SRCS    := $(SRC_DIR)/main.cpp $(SRC_DIR)/parser.cpp $(SRC_DIR)/renderer.cpp $(SRC_DIR)/rss.cpp
OBJS    := $(SRCS:.cpp=.o)
LIB_OBJS := $(SRC_DIR)/parser.o $(SRC_DIR)/renderer.o $(SRC_DIR)/rss.o
BIN     := blog
TEST_BIN := test_blog

help:
	@echo "Blog Generator - Available commands:"
	@echo "  make build   - Generate the static site"
	@echo "  make serve   - Build and serve locally (port 8000)"
	@echo "  make clean   - Remove generated files"
	@echo "  make test    - Run tests"

$(BIN): $(OBJS)
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LDFLAGS)

$(SRC_DIR)/%.o: $(SRC_DIR)/%.cpp
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) -c $< -o $@

build: $(BIN)
	./$(BIN) --config config.yml --source publish --output docs

serve: build
	@echo "Serving at http://localhost:8000"
	@cd docs && python3 -m http.server 8000

$(TEST_BIN): $(SRC_DIR)/test.o $(LIB_OBJS)
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LDFLAGS)

test: $(TEST_BIN)
	./$(TEST_BIN)

clean:
	rm -rf docs/*
	rm -f $(OBJS) $(SRC_DIR)/test.o $(BIN) $(TEST_BIN)
	@echo "Cleaned"

$(SRC_DIR)/main.o: $(SRC_DIR)/parser.h $(SRC_DIR)/renderer.h $(SRC_DIR)/rss.h
$(SRC_DIR)/parser.o: $(SRC_DIR)/parser.h
$(SRC_DIR)/renderer.o: $(SRC_DIR)/renderer.h $(SRC_DIR)/parser.h
$(SRC_DIR)/rss.o: $(SRC_DIR)/rss.h $(SRC_DIR)/parser.h
$(SRC_DIR)/test.o: $(SRC_DIR)/parser.h $(SRC_DIR)/renderer.h $(SRC_DIR)/rss.h
