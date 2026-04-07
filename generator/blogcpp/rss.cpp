#include "rss.h"
#include <sstream>
#include <array>
#include <ctime>
#include <algorithm>

static std::string xml_escape(const std::string& s) {
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

static std::string rfc2822_now() {
    auto t = std::time(nullptr);
    std::tm tm{};
    gmtime_r(&t, &tm);
    char buf[64];
    std::strftime(buf, sizeof(buf), "%a, %d %b %Y %H:%M:%S +0000", &tm);
    return buf;
}

static std::string rfc2822_from_iso(const std::string& iso) {
    int year = std::stoi(iso.substr(0, 4));
    int month = std::stoi(iso.substr(5, 2));
    int day = std::stoi(iso.substr(8, 2));

    std::tm tm{};
    tm.tm_year = year - 1900;
    tm.tm_mon = month - 1;
    tm.tm_mday = day;
    tm.tm_hour = 12;
    tm.tm_min = 0;
    tm.tm_sec = 0;
    timegm(&tm);

    char buf[64];
    std::strftime(buf, sizeof(buf), "%a, %d %b %Y %H:%M:%S +0000", &tm);
    return buf;
}

static int current_year() {
    auto t = std::time(nullptr);
    std::tm tm{};
    gmtime_r(&t, &tm);
    return tm.tm_year + 1900;
}

std::string generate_rss(const std::vector<Post>& posts, const Config& config) {
    std::ostringstream s;
    s << R"(<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0"
  xmlns:atom="http://www.w3.org/2005/Atom"
  xmlns:dc="http://purl.org/dc/elements/1.1/">
  <channel>
    <title>)" << xml_escape(config.title) << R"(</title>
    <link>)" << xml_escape(config.url) << R"(</link>
    <description>)" << xml_escape(config.description) << R"(</description>
    <language>en</language>
    <copyright>Copyright )" << current_year() << " " << xml_escape(config.author) << R"(</copyright>
    <lastBuildDate>)" << rfc2822_now() << R"(</lastBuildDate>
    <atom:link href=")" << config.url << R"(/feed.xml" rel="self" type="application/rss+xml"/>
)";

    auto limit = std::min(posts.size(), static_cast<size_t>(20));
    for (size_t i = 0; i < limit; ++i) {
        auto& p = posts[i];
        s << R"(    <item>
      <title><![CDATA[)" << p.title << R"(]]></title>
      <link>)" << config.url << "/posts/" << p.slug << R"(.html</link>
      <guid>)" << config.url << "/posts/" << p.slug << R"(.html</guid>
      <pubDate>)" << rfc2822_from_iso(p.date) << R"(</pubDate>
      <dc:creator>)" << xml_escape(config.author) << R"(</dc:creator>
      <description><![CDATA[)" << p.html << R"(]]></description>
    </item>
)";
    }

    s << R"(  </channel>
</rss>
)";
    return s.str();
}
