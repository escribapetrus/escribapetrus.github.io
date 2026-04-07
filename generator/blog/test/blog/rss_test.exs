defmodule Blog.RSSTest do
  use ExUnit.Case, async: true

  @config %{
    title: "Test Blog",
    description: "A test blog",
    author: "Test Author",
    url: "https://test.example.com"
  }

  @post %Blog.Parser{
    title: "RSS Post",
    slug: "rss-post",
    date: ~D[2025-04-10],
    tags: ["rss"],
    description: "Testing RSS",
    content: "# RSS\nContent",
    html: "<h1>RSS</h1>\n<p>Content</p>"
  }

  describe "generate/2" do
    test "returns valid RSS 2.0 XML" do
      xml = Blog.RSS.generate([@post], @config)

      assert xml =~ ~s(<?xml version="1.0" encoding="UTF-8"?>)
      assert xml =~ ~s(rss version="2.0")
      assert xml =~ "</rss>"
    end

    test "includes channel metadata" do
      xml = Blog.RSS.generate([@post], @config)

      assert xml =~ "<title>Test Blog</title>"
      assert xml =~ "<link>https://test.example.com</link>"
      assert xml =~ "<description>A test blog</description>"
      assert xml =~ "<language>en</language>"
    end

    test "includes copyright with current year" do
      xml = Blog.RSS.generate([@post], @config)
      year = Date.utc_today().year |> to_string()
      assert xml =~ "<copyright>Copyright #{year} Test Author</copyright>"
    end

    test "includes lastBuildDate" do
      xml = Blog.RSS.generate([@post], @config)
      assert xml =~ "<lastBuildDate>"
    end

    test "includes Atom self-link" do
      xml = Blog.RSS.generate([@post], @config)
      assert xml =~ ~s(href="https://test.example.com/feed.xml")
      assert xml =~ ~s(rel="self")
    end

    test "includes Dublin Core namespace" do
      xml = Blog.RSS.generate([@post], @config)
      assert xml =~ ~s(xmlns:dc="http://purl.org/dc/elements/1.1/")
    end

    test "includes item with all required fields" do
      xml = Blog.RSS.generate([@post], @config)

      assert xml =~ "<item>"
      assert xml =~ "<![CDATA[RSS Post]]>"
      assert xml =~ "<link>https://test.example.com/posts/rss-post.html</link>"
      assert xml =~ "<guid>https://test.example.com/posts/rss-post.html</guid>"
      assert xml =~ "<pubDate>"
      assert xml =~ "<dc:creator>Test Author</dc:creator>"
    end

    test "includes full HTML content in description" do
      xml = Blog.RSS.generate([@post], @config)
      assert xml =~ "<h1>RSS</h1>"
      assert xml =~ "<p>Content</p>"
    end

    test "formats pubDate in RFC 2822" do
      xml = Blog.RSS.generate([@post], @config)
      assert xml =~ "Thu, 10 Apr 2025 12:00:00 +0000"
    end

    test "limits to 20 posts" do
      posts = for i <- 1..25 do
        %{@post | title: "Post #{i}", slug: "post-#{i}", date: Date.add(~D[2025-01-01], i)}
      end

      xml = Blog.RSS.generate(posts, @config)
      count = length(Regex.scan(~r/<item>/, xml))
      assert count == 20
    end

    test "handles empty post list" do
      xml = Blog.RSS.generate([], @config)
      assert xml =~ "<channel>"
      refute xml =~ "<item>"
    end

    test "falls back to title when author is missing" do
      config = Map.delete(@config, :author)
      xml = Blog.RSS.generate([@post], config)
      assert xml =~ "<dc:creator>Test Blog</dc:creator>"
    end
  end
end
