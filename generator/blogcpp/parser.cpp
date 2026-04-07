#include "parser.h"
#include <fstream>
#include <sstream>
#include <algorithm>
#include <map>
#include <chrono>
#include <cstring>
#include <cstdlib>
#include <cmark.h>

static std::string trim(const std::string& s) {
    auto start = s.find_first_not_of(" \t\r\n");
    if (start == std::string::npos) return "";
    auto end = s.find_last_not_of(" \t\r\n");
    return s.substr(start, end - start + 1);
}

static std::string strip_quotes(const std::string& s) {
    if (s.size() >= 2 && ((s.front() == '"' && s.back() == '"') ||
                          (s.front() == '\'' && s.back() == '\'')))
        return s.substr(1, s.size() - 2);
    return s;
}

static std::string slugify(const std::string& title) {
    std::string result;
    for (char c : title) {
        if (std::isalnum(static_cast<unsigned char>(c)))
            result += static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
        else if (c == ' ' || c == '-')
            result += '-';
    }
    // collapse multiple hyphens
    std::string collapsed;
    for (char c : result) {
        if (c == '-' && !collapsed.empty() && collapsed.back() == '-') continue;
        collapsed += c;
    }
    return collapsed;
}

static std::string today_iso() {
    auto now = std::chrono::system_clock::now();
    auto tt = std::chrono::system_clock::to_time_t(now);
    std::tm tm{};
    gmtime_r(&tt, &tm);
    char buf[11];
    std::strftime(buf, sizeof(buf), "%Y-%m-%d", &tm);
    return buf;
}

static std::string read_file(const std::filesystem::path& path) {
    std::ifstream f(path);
    if (!f) return "";
    std::ostringstream ss;
    ss << f.rdbuf();
    return ss.str();
}

static std::map<std::string, std::string> parse_frontmatter(const std::string& yaml) {
    std::map<std::string, std::string> fm;
    std::istringstream ss(yaml);
    std::string line;
    while (std::getline(ss, line)) {
        auto colon = line.find(':');
        if (colon == std::string::npos) continue;
        auto key = trim(line.substr(0, colon));
        auto val = trim(line.substr(colon + 1));
        val = strip_quotes(val);
        fm[key] = val;
    }
    return fm;
}

static std::vector<std::string> parse_tags(const std::string& val) {
    std::vector<std::string> tags;
    if (val.empty()) return tags;

    std::string s = val;
    // strip brackets if present
    if (s.front() == '[' && s.back() == ']')
        s = s.substr(1, s.size() - 2);

    std::istringstream ss(s);
    std::string tag;
    while (std::getline(ss, tag, ',')) {
        auto t = trim(tag);
        if (!t.empty()) tags.push_back(t);
    }
    return tags;
}

static std::string md_to_html(const std::string& md) {
    char* raw = cmark_markdown_to_html(md.c_str(), md.size(), CMARK_OPT_DEFAULT);
    std::string html(raw);
    free(raw);
    return html;
}

Config load_config(const std::string& path) {
    Config config;
    std::string content = read_file(path);
    if (content.empty()) return config;

    auto fm = parse_frontmatter(content);
    if (fm.count("title"))       config.title       = fm["title"];
    if (fm.count("description")) config.description = fm["description"];
    if (fm.count("author"))      config.author      = fm["author"];
    if (fm.count("url"))         config.url         = fm["url"];
    if (fm.count("source_dir"))  config.source_dir  = fm["source_dir"];
    if (fm.count("output_dir"))  config.output_dir  = fm["output_dir"];
    return config;
}

std::optional<Post> parse_file(const std::filesystem::path& path) {
    std::string content = read_file(path);
    if (content.empty()) return std::nullopt;

    // must start with ---\n
    if (content.substr(0, 4) != "---\n") return std::nullopt;

    // find closing ---
    auto end = content.find("\n---\n", 3);
    if (end == std::string::npos) return std::nullopt;

    std::string yaml = content.substr(4, end - 4);
    std::string body = content.substr(end + 5);

    auto fm = parse_frontmatter(yaml);

    Post post;
    post.title = fm.count("title") ? fm["title"] : path.stem().string();
    post.slug = fm.count("slug") ? fm["slug"] : slugify(post.title);
    post.date = fm.count("date") ? fm["date"] : today_iso();
    post.tags = parse_tags(fm.count("tags") ? fm["tags"] : "");
    post.description = fm.count("description") ? fm["description"] :
                       (fm.count("summary") ? fm["summary"] : "");
    post.content = body;
    post.html = md_to_html(body);
    return post;
}

std::vector<Post> scan_and_parse(const Config& config) {
    std::vector<Post> posts;
    namespace fs = std::filesystem;

    if (!fs::exists(config.source_dir)) return posts;

    for (auto& entry : fs::directory_iterator(config.source_dir)) {
        if (!entry.is_regular_file()) continue;
        auto ext = entry.path().extension().string();
        if (ext != ".md" && ext != ".markdown") continue;

        auto post = parse_file(entry.path());
        if (post) posts.push_back(std::move(*post));
    }

    std::sort(posts.begin(), posts.end(), [](const Post& a, const Post& b) {
        return a.date > b.date;
    });

    return posts;
}
