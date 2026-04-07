#include "renderer.h"
#include <sstream>
#include <array>

static std::string html_escape(const std::string& s) {
    std::string out;
    out.reserve(s.size());
    for (char c : s) {
        switch (c) {
            case '&': out += "&amp;";  break;
            case '<': out += "&lt;";   break;
            case '>': out += "&gt;";   break;
            default:  out += c;
        }
    }
    return out;
}

static std::string format_date_long(const std::string& iso) {
    static const std::array<const char*, 12> months = {
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    };

    int year = std::stoi(iso.substr(0, 4));
    int month = std::stoi(iso.substr(5, 2));
    int day = std::stoi(iso.substr(8, 2));

    std::ostringstream ss;
    ss << months[month - 1] << " ";
    if (day < 10) ss << "0";
    ss << day << ", " << year;
    return ss.str();
}

std::string render_post(const Post& post, const Config& config) {
    std::ostringstream s;
    s << R"(<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>)" << html_escape(post.title) << " - " << html_escape(config.title) << R"(</title>
  <link rel="stylesheet" href="../style.css">
  <link rel="alternate" type="application/rss+xml" title="RSS" href="../feed.xml">
</head>
<body>
  <header>
    <nav><a href="../index.html">&larr; )" << html_escape(config.title) << R"(</a> <a href="../feed.xml">[RSS]</a></nav>
  </header>
  <main>
    <article>
      <header>
        <h1>)" << html_escape(post.title) << R"(</h1>
        <time datetime=")" << post.date << R"(">)" << format_date_long(post.date) << R"(</time>
      </header>
      <div class="content">)" << post.html << R"(</div>
    </article>
  </main>
  <footer><p>)" << html_escape(config.author) << R"(</p></footer>
</body>
</html>
)";
    return s.str();
}

std::string render_index(const std::vector<Post>& posts, const Config& config) {
    std::ostringstream items;
    for (auto& p : posts) {
        items << "<li><time>" << p.date
              << "</time> <a href=\"posts/" << p.slug << ".html\">"
              << html_escape(p.title) << "</a></li>\n";
    }

    std::ostringstream s;
    s << R"(<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>)" << html_escape(config.title) << R"(</title>
  <link rel="stylesheet" href="style.css">
  <link rel="alternate" type="application/rss+xml" title="RSS" href="feed.xml">
</head>
<body>
  <header>
    <h1>)" << html_escape(config.title) << R"(</h1>
    <p>)" << html_escape(config.description) << R"(</p>
    <nav><a href="feed.xml">[RSS]</a></nav>
  </header>
  <main><section class="posts"><h2>Posts</h2><ul>)" << items.str() << R"(</ul></section></main>
  <footer><p>)" << html_escape(config.author) << R"(</p></footer>
</body>
</html>
)";
    return s.str();
}

std::string css() {
    return R"(:root { --bg: #fff; --fg: #222; --link: #00e; --code-bg: #f5f5f5; --border: #ccc; }
@media (prefers-color-scheme: dark) { :root { --bg: #1a1a1a; --fg: #e0e0e0; --link: #6af; --code-bg: #2a2a2a; --border: #444; } }
* { box-sizing: border-box; }
body { font-family: serif; line-height: 1.6; max-width: 42rem; margin: 0 auto; padding: 2rem 1rem; background: var(--bg); color: var(--fg); }
a { color: var(--link); }
header { margin-bottom: 2rem; border-bottom: 1px solid var(--border); padding-bottom: 1rem; }
header h1 { margin: 0 0 0.5rem 0; }
header p { margin: 0; color: #666; }
article header { border-bottom: none; }
article header time { color: #666; font-size: 0.9rem; }
.content { margin-top: 2rem; }
.content h1, .content h2, .content h3 { margin-top: 2rem; }
.content code { background: var(--code-bg); padding: 0.1rem 0.3rem; font-family: monospace; }
.content pre { background: var(--code-bg); padding: 1rem; overflow-x: auto; }
.posts ul { list-style: none; padding: 0; }
.posts li { margin: 0.5rem 0; }
.posts time { font-family: monospace; color: #666; margin-right: 1rem; }
footer { margin-top: 3rem; padding-top: 1rem; border-top: 1px solid var(--border); font-size: 0.9rem; color: #666; }
)";
}
