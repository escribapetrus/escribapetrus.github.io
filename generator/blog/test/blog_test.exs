defmodule BlogTest do
  use ExUnit.Case

  @tmp_dir Path.join(System.tmp_dir!(), "blog_build_test_#{:erlang.unique_integer([:positive])}")
  @source_dir Path.join(@tmp_dir, "source")
  @output_dir Path.join(@tmp_dir, "output")

  setup do
    File.mkdir_p!(@source_dir)
    File.mkdir_p!(@output_dir)

    File.write!(Path.join(@source_dir, "hello.md"), """
    ---
    title: "Hello World"
    date: 2025-03-01
    description: "First post"
    ---
    # Hello

    Welcome to the blog.
    """)

    File.write!(Path.join(@source_dir, "second.md"), """
    ---
    title: "Second Post"
    date: 2025-04-01
    description: "Another post"
    ---
    More content here.
    """)

    on_exit(fn -> File.rm_rf!(@tmp_dir) end)
    :ok
  end

  describe "build/1" do
    test "generates all output files" do
      Blog.build(source_dir: @source_dir, output_dir: @output_dir)

      assert File.exists?(Path.join(@output_dir, "index.html"))
      assert File.exists?(Path.join(@output_dir, "feed.xml"))
      assert File.exists?(Path.join(@output_dir, "style.css"))
      assert File.exists?(Path.join([@output_dir, "posts", "hello-world.html"]))
      assert File.exists?(Path.join([@output_dir, "posts", "second-post.html"]))
    end

    test "index contains links to all posts" do
      Blog.build(source_dir: @source_dir, output_dir: @output_dir)

      index = File.read!(Path.join(@output_dir, "index.html"))
      assert index =~ "Hello World"
      assert index =~ "Second Post"
      assert index =~ "hello-world.html"
      assert index =~ "second-post.html"
    end

    test "feed.xml contains all posts" do
      Blog.build(source_dir: @source_dir, output_dir: @output_dir)

      feed = File.read!(Path.join(@output_dir, "feed.xml"))
      assert feed =~ "Hello World"
      assert feed =~ "Second Post"
    end

    test "post HTML contains rendered content" do
      Blog.build(source_dir: @source_dir, output_dir: @output_dir)

      html = File.read!(Path.join([@output_dir, "posts", "hello-world.html"]))
      assert html =~ "Hello World"
      assert html =~ "Welcome to the blog"
    end

    test "uses default config values when no config file exists" do
      Blog.build(
        config: "/nonexistent/config.yml",
        source_dir: @source_dir,
        output_dir: @output_dir
      )

      index = File.read!(Path.join(@output_dir, "index.html"))
      assert index =~ "Blog"
    end

    test "handles empty source directory" do
      empty_dir = Path.join(@tmp_dir, "empty")
      File.mkdir_p!(empty_dir)

      Blog.build(source_dir: empty_dir, output_dir: @output_dir)

      assert File.exists?(Path.join(@output_dir, "index.html"))
      assert File.exists?(Path.join(@output_dir, "feed.xml"))
    end
  end
end
