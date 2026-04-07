#include "parser.h"
#include "renderer.h"
#include "rss.h"
#include <iostream>
#include <fstream>
#include <filesystem>

namespace fs = std::filesystem;

static void write_file(const fs::path& path, const std::string& content) {
    std::ofstream f(path);
    f << content;
}

int main(int argc, char* argv[]) {
    std::string config_path = "config.yml";
    std::string source_dir, output_dir;

    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        if (arg == "--config" && i + 1 < argc)      config_path = argv[++i];
        else if (arg == "--source" && i + 1 < argc)  source_dir = argv[++i];
        else if (arg == "--output" && i + 1 < argc)  output_dir = argv[++i];
    }

    Config config = load_config(config_path);
    if (!source_dir.empty()) config.source_dir = source_dir;
    if (!output_dir.empty()) config.output_dir = output_dir;

    std::cout << "Building blog...\n";

    fs::create_directories(config.output_dir);
    fs::create_directories(fs::path(config.output_dir) / "posts");

    auto posts = scan_and_parse(config);
    std::cout << "   Found " << posts.size() << " posts\n";

    for (auto& post : posts) {
        auto path = fs::path(config.output_dir) / "posts" / (post.slug + ".html");
        write_file(path, render_post(post, config));
        std::cout << "   + " << post.slug << "\n";
    }

    write_file(fs::path(config.output_dir) / "index.html", render_index(posts, config));
    std::cout << "   + index.html\n";

    write_file(fs::path(config.output_dir) / "feed.xml", generate_rss(posts, config));
    std::cout << "   + feed.xml\n";

    write_file(fs::path(config.output_dir) / "style.css", css());
    std::cout << "   + style.css\n";

    std::cout << "Done!\n";
    return 0;
}
