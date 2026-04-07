CXX      := c++
CXXFLAGS := -std=c++17 -Wall -Wextra -O2
CMARK    := $(shell brew --prefix cmark 2>/dev/null || echo /usr/local)
CPPFLAGS := -I$(CMARK)/include
LDFLAGS  := -L$(CMARK)/lib -lcmark

SRCS := main.cpp parser.cpp renderer.cpp rss.cpp
OBJS := $(SRCS:.cpp=.o)
BIN  := blog

all: $(BIN)

$(BIN): $(OBJS)
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LDFLAGS)

%.o: %.cpp
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) -c $< -o $@

clean:
	rm -f $(OBJS) $(BIN)

.PHONY: all clean

main.o: parser.h renderer.h rss.h
parser.o: parser.h
renderer.o: renderer.h parser.h
rss.o: rss.h parser.h
