defmodule Blog.ParserTest do
  use ExUnit.Case, async: true

  @fixtures_dir Path.join(System.tmp_dir!(), "blog_parser_test_#{:erlang.unique_integer([:positive])}")

  setup_all do
    File.mkdir_p!(@fixtures_dir)
    on_exit(fn -> File.rm_rf!(@fixtures_dir) end)
    :ok
  end

  defp write_fixture(name, content) do
    path = Path.join(@fixtures_dir, name)
    File.write!(path, content)
    path
  end

  describe "parse_file/1 with markdown" do
    test "parses YAML frontmatter and markdown body" do
      path = write_fixture("post.md", """
      ---
      title: "Test Post"
      date: 2025-01-15
      description: "A test post"
      tags: [elixir, blog]
      ---
      # Hello

      This is a **bold** paragraph.
      """)

      post = Blog.Parser.parse_file(path)

      assert post.title == "Test Post"
      assert post.date == ~D[2025-01-15]
      assert post.description == "A test post"
      assert post.tags == ["elixir", "blog"]
      assert post.slug == "test-post"
      assert post.html =~ "<strong>bold</strong>"
      assert post.html =~ "Hello"
    end

    test "generates slug from title when slug is absent" do
      path = write_fixture("no-slug.md", """
      ---
      title: "My Great Post!"
      date: 2025-06-01
      ---
      Content here.
      """)

      post = Blog.Parser.parse_file(path)
      assert post.slug == "my-great-post"
    end

    test "uses explicit slug when provided" do
      path = write_fixture("custom-slug.md", """
      ---
      title: "Some Title"
      slug: "custom-slug-here"
      date: 2025-06-01
      ---
      Content.
      """)

      post = Blog.Parser.parse_file(path)
      assert post.slug == "custom-slug-here"
    end

    test "defaults date to today when missing" do
      path = write_fixture("no-date.md", """
      ---
      title: "No Date"
      ---
      Body.
      """)

      post = Blog.Parser.parse_file(path)
      assert post.date == Date.utc_today()
    end

    test "handles empty tags gracefully" do
      path = write_fixture("no-tags.md", """
      ---
      title: "No Tags"
      date: 2025-01-01
      ---
      Body.
      """)

      post = Blog.Parser.parse_file(path)
      assert post.tags == []
    end
  end

  describe "parse_file/1 error cases" do
    test "returns nil for nonexistent file" do
      assert Blog.Parser.parse_file("/nonexistent/path.md") == nil
    end

    test "returns nil for file without frontmatter" do
      path = write_fixture("no-frontmatter.md", "Just plain text, no frontmatter.")
      assert Blog.Parser.parse_file(path) == nil
    end

    test "returns nil for unsupported format content" do
      path = write_fixture("bad.md", "No dashes or org headers here\nJust text.")
      assert Blog.Parser.parse_file(path) == nil
    end
  end
end
