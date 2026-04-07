#pragma once

#include "parser.h"
#include <string>
#include <vector>

std::string generate_rss(const std::vector<Post>& posts, const Config& config);
