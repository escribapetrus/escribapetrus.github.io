defmodule Blog do
  @moduledoc "Static blog generator"

  alias Blog.{Parser, Renderer, RSS}

  @default_config %{
    title: "Blog",
    description: "A personal blog",
    author: "Anonymous",
    url: "https://example.com",
    source_dir: "publish",
    output_dir: "docs"
  }

  def build(opts \\ []) do
    config = load_config(opts)
    IO.puts("📚 Building blog...")

    File.mkdir_p!(config.output_dir)
    File.mkdir_p!(Path.join(config.output_dir, "posts"))

    posts =
      config.source_dir
      |> list_source_files()
      |> Enum.map(&Parser.parse_file/1)
      |> Enum.filter(&(&1 != nil))
      |> Enum.sort_by(& &1.date, {:desc, Date})

    IO.puts("   Found #{length(posts)} posts")

    Enum.each(posts, fn post ->
      html = Renderer.render_post(post, config)
      path = Path.join([config.output_dir, "posts", "#{post.slug}.html"])
      File.write!(path, html)
      IO.puts("   ✓ #{post.slug}")
    end)

    File.write!(Path.join(config.output_dir, "index.html"), Renderer.render_index(posts, config))
    IO.puts("   ✓ index.html")

    File.write!(Path.join(config.output_dir, "feed.xml"), RSS.generate(posts, config))
    IO.puts("   ✓ feed.xml")

    File.write!(Path.join(config.output_dir, "style.css"), Renderer.css())
    IO.puts("   ✓ style.css")

    IO.puts("✅ Done!")
  end

  defp load_config(opts) do
    config_path = Keyword.get(opts, :config, "config.yml")
    file_config = if File.exists?(config_path) do
      config_path |> YamlElixir.read_from_file!() |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
    else
      %{}
    end
    @default_config |> Map.merge(file_config) |> Map.merge(Map.new(opts))
  end

  defp list_source_files(dir) do
    case File.ls(dir) do
      {:ok, files} -> files |> Enum.filter(&valid?/1) |> Enum.map(&Path.join(dir, &1))
      _ -> []
    end
  end

  defp valid?(f), do: Path.extname(f) in [".md", ".markdown"]
end

defmodule Blog.CLI do
  def main(_args), do: Blog.build()
end
