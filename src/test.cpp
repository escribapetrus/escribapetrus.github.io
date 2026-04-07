#include "parser.h"
#include "renderer.h"
#include "rss.h"
#include <iostream>
#include <fstream>
#include <filesystem>
#include <sstream>
#include <cassert>
#include <cstring>
#include <unistd.h>

namespace fs = std::filesystem;

static int tests_run = 0;
static int tests_failed = 0;

#define TEST(name) static void name()
#define RUN(name) do { \
    std::cout << "  " #name << std::flush; \
    try { name(); std::cout << " OK\n"; tests_run++; } \
    catch (const std::exception& e) { \
        std::cout << " FAIL: " << e.what() << "\n"; tests_run++; tests_failed++; \
    } \
} while(0)

#define ASSERT(expr) do { if (!(expr)) throw std::runtime_error( \
    std::string(__FILE__) + ":" + std::to_string(__LINE__) + ": " #expr); } while(0)
#define ASSERT_EQ(a, b) do { if ((a) != (b)) throw std::runtime_error( \
    std::string(__FILE__) + ":" + std::to_string(__LINE__) + ": " #a " != " #b \
    + "\n    left:  " + std::string(a) + "\n    right: " + std::string(b)); } while(0)
#define ASSERT_CONTAINS(haystack, needle) do { \
    if (std::string(haystack).find(needle) == std::string::npos) \
        throw std::runtime_error(std::string(__FILE__) + ":" + std::to_string(__LINE__) \
        + ": \"" + std::string(needle) + "\" not found in output"); } while(0)
#define ASSERT_NOT_CONTAINS(haystack, needle) do { \
    if (std::string(haystack).find(needle) != std::string::npos) \
        throw std::runtime_error(std::string(__FILE__) + ":" + std::to_string(__LINE__) \
        + ": \"" + std::string(needle) + "\" unexpectedly found in output"); } while(0)

// -- Helpers --

static std::string tmp_dir;

static void setup_tmp() {
    tmp_dir = fs::temp_directory_path() / ("blog_test_" + std::to_string(getpid()));
    fs::create_directories(tmp_dir);
}

static void cleanup_tmp() {
    fs::remove_all(tmp_dir);
}

static std::string write_fixture(const std::string& name, const std::string& content) {
    auto path = fs::path(tmp_dir) / name;
    std::ofstream f(path);
    f << content;
    return path.string();
}

static Post make_post() {
    return Post{
        .title = "Test Post",
        .slug = "test-post",
        .date = "2025-06-15",
        .tags = {"cpp", "blog"},
        .description = "A test post",
        .content = "# Hello\nWorld",
        .html = "<h1>Hello</h1>\n<p>World</p>\n"
    };
}

static Config make_config() {
    return Config{
        .title = "Test Blog",
        .description = "A test blog",
        .author = "Test Author",
        .url = "https://test.example.com",
        .source_dir = "publish",
        .output_dir = "docs"
    };
}

// -- Parser tests --

TEST(parse_file_with_frontmatter) {
    auto path = write_fixture("post.md",
        "---\n"
        "title: \"Test Post\"\n"
        "date: 2025-01-15\n"
        "description: \"A test post\"\n"
        "tags: [elixir, blog]\n"
        "---\n"
        "# Hello\n\n"
        "This is **bold**.\n"
    );
    auto post = parse_file(path);
    ASSERT(post.has_value());
    ASSERT_EQ(post->title, "Test Post");
    ASSERT_EQ(post->date, "2025-01-15");
    ASSERT_EQ(post->description, "A test post");
    ASSERT_EQ(post->slug, "test-post");
    ASSERT(post->tags.size() == 2);
    ASSERT_EQ(post->tags[0], "elixir");
    ASSERT_EQ(post->tags[1], "blog");
    ASSERT_CONTAINS(post->html, "<strong>bold</strong>");
}

TEST(parse_file_generates_slug) {
    auto path = write_fixture("slug.md",
        "---\n"
        "title: \"My Great Post!\"\n"
        "date: 2025-06-01\n"
        "---\n"
        "Content.\n"
    );
    auto post = parse_file(path);
    ASSERT(post.has_value());
    ASSERT_EQ(post->slug, "my-great-post");
}

TEST(parse_file_uses_explicit_slug) {
    auto path = write_fixture("custom.md",
        "---\n"
        "title: \"Some Title\"\n"
        "slug: custom-slug-here\n"
        "date: 2025-06-01\n"
        "---\n"
        "Content.\n"
    );
    auto post = parse_file(path);
    ASSERT(post.has_value());
    ASSERT_EQ(post->slug, "custom-slug-here");
}

TEST(parse_file_defaults_date) {
    auto path = write_fixture("nodate.md",
        "---\n"
        "title: \"No Date\"\n"
        "---\n"
        "Body.\n"
    );
    auto post = parse_file(path);
    ASSERT(post.has_value());
    ASSERT(post->date.size() == 10); // YYYY-MM-DD
}

TEST(parse_file_empty_tags) {
    auto path = write_fixture("notags.md",
        "---\n"
        "title: \"No Tags\"\n"
        "date: 2025-01-01\n"
        "---\n"
        "Body.\n"
    );
    auto post = parse_file(path);
    ASSERT(post.has_value());
    ASSERT(post->tags.empty());
}

TEST(parse_file_nonexistent) {
    auto post = parse_file("/nonexistent/path.md");
    ASSERT(!post.has_value());
}

TEST(parse_file_no_frontmatter) {
    auto path = write_fixture("plain.md", "Just plain text.");
    auto post = parse_file(path);
    ASSERT(!post.has_value());
}

TEST(load_config_from_file) {
    auto path = write_fixture("config.yml",
        "title: \"My Blog\"\n"
        "author: \"Pedro\"\n"
        "url: \"https://example.com\"\n"
    );
    auto config = load_config(path);
    ASSERT_EQ(config.title, "My Blog");
    ASSERT_EQ(config.author, "Pedro");
    ASSERT_EQ(config.url, "https://example.com");
}

TEST(load_config_defaults) {
    auto config = load_config("/nonexistent/config.yml");
    ASSERT_EQ(config.title, "Blog");
    ASSERT_EQ(config.author, "Anonymous");
}

TEST(scan_and_parse_finds_posts) {
    auto dir = fs::path(tmp_dir) / "posts_dir";
    fs::create_directories(dir);

    std::ofstream(dir / "a.md")
        << "---\ntitle: \"AAA\"\ndate: 2025-01-01\n---\nA\n";
    std::ofstream(dir / "b.md")
        << "---\ntitle: \"BBB\"\ndate: 2025-02-01\n---\nB\n";
    std::ofstream(dir / "skip.txt")
        << "not a markdown file";

    Config config;
    config.source_dir = dir.string();
    auto posts = scan_and_parse(config);
    ASSERT(posts.size() == 2);
    // sorted descending by date
    ASSERT_EQ(posts[0].title, "BBB");
    ASSERT_EQ(posts[1].title, "AAA");
}

TEST(scan_and_parse_empty_dir) {
    auto dir = fs::path(tmp_dir) / "empty_dir";
    fs::create_directories(dir);

    Config config;
    config.source_dir = dir.string();
    auto posts = scan_and_parse(config);
    ASSERT(posts.empty());
}

// -- Renderer tests --

TEST(render_post_complete_html) {
    auto html = render_post(make_post(), make_config());
    ASSERT_CONTAINS(html, "<!DOCTYPE html>");
    ASSERT_CONTAINS(html, "<title>Test Post - Test Blog</title>");
    ASSERT_CONTAINS(html, "<h1>Hello</h1>");
    ASSERT_CONTAINS(html, "June 15, 2025");
    ASSERT_CONTAINS(html, "datetime=\"2025-06-15\"");
    ASSERT_CONTAINS(html, "href=\"../index.html\"");
    ASSERT_CONTAINS(html, "application/rss+xml");
    ASSERT_CONTAINS(html, "Test Author");
}

TEST(render_post_escapes_html) {
    auto post = make_post();
    post.title = "A <script> & \"test\"";
    auto html = render_post(post, make_config());
    ASSERT_CONTAINS(html, "A &lt;script&gt; &amp; \"test\"");
    ASSERT_NOT_CONTAINS(html, "<script>");
}

TEST(render_index_lists_posts) {
    auto post1 = make_post();
    auto post2 = make_post();
    post2.title = "Second Post";
    post2.slug = "second-post";
    post2.date = "2025-07-01";

    auto html = render_index({post1, post2}, make_config());
    ASSERT_CONTAINS(html, "<!DOCTYPE html>");
    ASSERT_CONTAINS(html, "<title>Test Blog</title>");
    ASSERT_CONTAINS(html, "A test blog");
    ASSERT_CONTAINS(html, "posts/test-post.html");
    ASSERT_CONTAINS(html, "posts/second-post.html");
    ASSERT_CONTAINS(html, "application/rss+xml");
}

TEST(render_index_empty) {
    auto html = render_index({}, make_config());
    ASSERT_CONTAINS(html, "<!DOCTYPE html>");
    ASSERT_CONTAINS(html, "Posts");
}

TEST(css_returns_content) {
    auto c = css();
    ASSERT(!c.empty());
    ASSERT_CONTAINS(c, "prefers-color-scheme: dark");
    ASSERT_CONTAINS(c, "body {");
    ASSERT_CONTAINS(c, ".content");
    ASSERT_CONTAINS(c, ".posts");
}

// -- RSS tests --

TEST(rss_valid_xml) {
    auto xml = generate_rss({make_post()}, make_config());
    ASSERT_CONTAINS(xml, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
    ASSERT_CONTAINS(xml, "rss version=\"2.0\"");
    ASSERT_CONTAINS(xml, "</rss>");
}

TEST(rss_channel_metadata) {
    auto xml = generate_rss({make_post()}, make_config());
    ASSERT_CONTAINS(xml, "<title>Test Blog</title>");
    ASSERT_CONTAINS(xml, "<link>https://test.example.com</link>");
    ASSERT_CONTAINS(xml, "<description>A test blog</description>");
    ASSERT_CONTAINS(xml, "<language>en</language>");
}

TEST(rss_copyright) {
    auto xml = generate_rss({make_post()}, make_config());
    ASSERT_CONTAINS(xml, "<copyright>Copyright ");
    ASSERT_CONTAINS(xml, "Test Author</copyright>");
}

TEST(rss_build_date) {
    auto xml = generate_rss({make_post()}, make_config());
    ASSERT_CONTAINS(xml, "<lastBuildDate>");
}

TEST(rss_atom_self_link) {
    auto xml = generate_rss({make_post()}, make_config());
    ASSERT_CONTAINS(xml, "href=\"https://test.example.com/feed.xml\"");
    ASSERT_CONTAINS(xml, "rel=\"self\"");
}

TEST(rss_dc_namespace) {
    auto xml = generate_rss({make_post()}, make_config());
    ASSERT_CONTAINS(xml, "xmlns:dc=\"http://purl.org/dc/elements/1.1/\"");
}

TEST(rss_item_fields) {
    auto xml = generate_rss({make_post()}, make_config());
    ASSERT_CONTAINS(xml, "<item>");
    ASSERT_CONTAINS(xml, "<![CDATA[Test Post]]>");
    ASSERT_CONTAINS(xml, "<link>https://test.example.com/posts/test-post.html</link>");
    ASSERT_CONTAINS(xml, "<guid>https://test.example.com/posts/test-post.html</guid>");
    ASSERT_CONTAINS(xml, "<pubDate>");
    ASSERT_CONTAINS(xml, "<dc:creator>Test Author</dc:creator>");
}

TEST(rss_full_html_in_description) {
    auto xml = generate_rss({make_post()}, make_config());
    ASSERT_CONTAINS(xml, "<h1>Hello</h1>");
    ASSERT_CONTAINS(xml, "<p>World</p>");
}

TEST(rss_date_format) {
    auto xml = generate_rss({make_post()}, make_config());
    ASSERT_CONTAINS(xml, "Sun, 15 Jun 2025 12:00:00 +0000");
}

TEST(rss_limits_to_20) {
    std::vector<Post> posts;
    for (int i = 0; i < 25; i++) {
        auto p = make_post();
        p.slug = "post-" + std::to_string(i);
        posts.push_back(p);
    }
    auto xml = generate_rss(posts, make_config());
    size_t count = 0;
    size_t pos = 0;
    while ((pos = xml.find("<item>", pos)) != std::string::npos) {
        count++;
        pos++;
    }
    ASSERT(count == 20);
}

TEST(rss_empty_posts) {
    auto xml = generate_rss({}, make_config());
    ASSERT_CONTAINS(xml, "<channel>");
    ASSERT_NOT_CONTAINS(xml, "<item>");
}

// -- Main --

int main() {
    setup_tmp();

    std::cout << "Parser:\n";
    RUN(parse_file_with_frontmatter);
    RUN(parse_file_generates_slug);
    RUN(parse_file_uses_explicit_slug);
    RUN(parse_file_defaults_date);
    RUN(parse_file_empty_tags);
    RUN(parse_file_nonexistent);
    RUN(parse_file_no_frontmatter);
    RUN(load_config_from_file);
    RUN(load_config_defaults);
    RUN(scan_and_parse_finds_posts);
    RUN(scan_and_parse_empty_dir);

    std::cout << "Renderer:\n";
    RUN(render_post_complete_html);
    RUN(render_post_escapes_html);
    RUN(render_index_lists_posts);
    RUN(render_index_empty);
    RUN(css_returns_content);

    std::cout << "RSS:\n";
    RUN(rss_valid_xml);
    RUN(rss_channel_metadata);
    RUN(rss_copyright);
    RUN(rss_build_date);
    RUN(rss_atom_self_link);
    RUN(rss_dc_namespace);
    RUN(rss_item_fields);
    RUN(rss_full_html_in_description);
    RUN(rss_date_format);
    RUN(rss_limits_to_20);
    RUN(rss_empty_posts);

    cleanup_tmp();

    std::cout << "\n" << tests_run << " tests, " << tests_failed << " failures\n";
    return tests_failed ? 1 : 0;
}
