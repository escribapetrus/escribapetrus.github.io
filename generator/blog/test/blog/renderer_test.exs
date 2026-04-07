defmodule Blog.RendererTest do
  use ExUnit.Case, async: true

  @config %{
    title: "Test Blog",
    description: "A test blog",
    author: "Test Author",
    url: "https://test.example.com"
  }

  @post %Blog.Parser{
    title: "My Post",
    slug: "my-post",
    date: ~D[2025-06-15],
    tags: ["elixir"],
    description: "A post about testing",
    content: "# Hello\nWorld",
    html: "<h1>Hello</h1>\n<p>World</p>"
  }

  describe "render_post/2" do
    test "returns a complete HTML document" do
      html = Blog.Renderer.render_post(@post, @config)

      assert html =~ "<!DOCTYPE html>"
      assert html =~ "<html lang=\"en\">"
      assert html =~ "</html>"
    end

    test "includes post title in page title" do
      html = Blog.Renderer.render_post(@post, @config)
      assert html =~ "<title>My Post - Test Blog</title>"
    end

    test "includes post content" do
      html = Blog.Renderer.render_post(@post, @config)
      assert html =~ "<h1>Hello</h1>"
      assert html =~ "<p>World</p>"
    end

    test "includes formatted date" do
      html = Blog.Renderer.render_post(@post, @config)
      assert html =~ "June 15, 2025"
      assert html =~ ~s(datetime="2025-06-15")
    end

    test "includes navigation back to index" do
      html = Blog.Renderer.render_post(@post, @config)
      assert html =~ ~s(href="../index.html")
      assert html =~ "Test Blog"
    end

    test "includes RSS link" do
      html = Blog.Renderer.render_post(@post, @config)
      assert html =~ ~s(type="application/rss+xml")
      assert html =~ ~s(href="../feed.xml")
    end

    test "includes author in footer" do
      html = Blog.Renderer.render_post(@post, @config)
      assert html =~ "Test Author"
    end

    test "escapes HTML entities in title" do
      post = %{@post | title: "A <script> & \"test\""}
      html = Blog.Renderer.render_post(post, @config)
      assert html =~ "A &lt;script&gt; &amp; \"test\""
      refute html =~ "<script>"
    end
  end

  describe "render_index/2" do
    test "returns a complete HTML document" do
      html = Blog.Renderer.render_index([@post], @config)

      assert html =~ "<!DOCTYPE html>"
      assert html =~ "</html>"
    end

    test "includes site title and description" do
      html = Blog.Renderer.render_index([@post], @config)
      assert html =~ "<title>Test Blog</title>"
      assert html =~ "A test blog"
    end

    test "lists posts with links" do
      html = Blog.Renderer.render_index([@post], @config)
      assert html =~ ~s(href="posts/my-post.html")
      assert html =~ "My Post"
    end

    test "includes post dates" do
      html = Blog.Renderer.render_index([@post], @config)
      assert html =~ "2025-06-15"
    end

    test "handles multiple posts" do
      post2 = %{@post | title: "Second Post", slug: "second-post", date: ~D[2025-07-01]}
      html = Blog.Renderer.render_index([@post, post2], @config)
      assert html =~ "My Post"
      assert html =~ "Second Post"
    end

    test "handles empty post list" do
      html = Blog.Renderer.render_index([], @config)
      assert html =~ "<!DOCTYPE html>"
      assert html =~ "Posts"
    end

    test "includes RSS link" do
      html = Blog.Renderer.render_index([@post], @config)
      assert html =~ ~s(type="application/rss+xml")
    end
  end

  describe "css/0" do
    test "returns a non-empty CSS string" do
      css = Blog.Renderer.css()
      assert is_binary(css)
      assert String.length(css) > 0
    end

    test "includes dark mode media query" do
      assert Blog.Renderer.css() =~ "prefers-color-scheme: dark"
    end

    test "includes base styling rules" do
      css = Blog.Renderer.css()
      assert css =~ "body {"
      assert css =~ "font-family"
      assert css =~ ".content"
      assert css =~ ".posts"
    end
  end
end
