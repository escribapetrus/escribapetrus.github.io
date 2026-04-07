#pragma once

#include <string>
#include <vector>
#include <optional>
#include <filesystem>

struct Post {
    std::string title;
    std::string slug;
    std::string date;
    std::vector<std::string> tags;
    std::string description;
    std::string content;
    std::string html;
};

struct Config {
    std::string title       = "Blog";
    std::string description = "A personal blog";
    std::string author      = "Anonymous";
    std::string url         = "https://example.com";
    std::string source_dir  = "publish";
    std::string output_dir  = "docs";
};

Config load_config(const std::string& path);
std::optional<Post> parse_file(const std::filesystem::path& path);
std::vector<Post> scan_and_parse(const Config& config);
