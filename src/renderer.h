#pragma once

#include "parser.h"
#include <string>
#include <vector>

std::string render_post(const Post& post, const Config& config);
std::string render_index(const std::vector<Post>& posts, const Config& config);
std::string css();
