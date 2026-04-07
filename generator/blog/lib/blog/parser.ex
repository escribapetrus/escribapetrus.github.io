defmodule Blog.Parser do
  defstruct [:title, :slug, :date, :tags, :description, :content, :html]

  def parse_file(path) do
    case File.read(path) do
      {:ok, content} -> parse(content, path)
      _ -> nil
    end
  end

  defp parse(content, path) do
    case parse_frontmatter(content, path) do
      {fm, body} ->
        html = if String.ends_with?(path, ".org"), do: org_to_html(body), else: md_to_html(body)
        build_post(fm, body, html, path)
      nil -> nil
    end
  end

  defp parse_frontmatter(content, path) do
    cond do
      String.starts_with?(content, "---") -> parse_yaml_frontmatter(content)
      String.starts_with?(content, "#+") -> parse_org_frontmatter(content)
      true -> nil
    end
  end

  defp parse_yaml_frontmatter(content) do
    case Regex.run(~r/\A---\n(.*?)\n---\n(.*)/s, content) do
      [_, yaml, body] -> {YamlElixir.read_from_string!(yaml), body}
      _ -> nil
    end
  end

  defp parse_org_frontmatter(content) do
    lines = String.split(content, "\n")
    {props, body} = Enum.split_while(lines, &(String.starts_with?(&1, "#+") or &1 == ""))
    fm = props
      |> Enum.filter(&String.starts_with?(&1, "#+"))
      |> Enum.map(fn line ->
        case Regex.run(~r/^#\+(\w+):\s*(.*)$/, line) do
          [_, k, v] -> {String.downcase(k), String.trim(v)}
          _ -> nil
        end
      end)
      |> Enum.filter(&(&1 != nil))
      |> Map.new()
    {fm, Enum.join(body, "\n")}
  end

  defp build_post(fm, content, html, path) do
    title = get(fm, ["title"], Path.basename(path, Path.extname(path)))
    %__MODULE__{
      title: title,
      slug: get(fm, ["slug"], slugify(title)),
      date: parse_date(get(fm, ["date"], nil)),
      tags: parse_tags(get(fm, ["tags"], [])),
      description: get(fm, ["description", "summary"], ""),
      content: content,
      html: html
    }
  end

  defp get(fm, keys, default) do
    Enum.find_value(keys, default, &(Map.get(fm, &1) || Map.get(fm, String.to_atom(&1))))
  end

  defp parse_date(nil), do: Date.utc_today()
  defp parse_date(d) when is_binary(d), do: case Date.from_iso8601(d), do: ({:ok, d} -> d; _ -> Date.utc_today())
  defp parse_date(d), do: d

  defp parse_tags(t) when is_list(t), do: t
  defp parse_tags(t) when is_binary(t), do: String.split(t, ",") |> Enum.map(&String.trim/1)
  defp parse_tags(_), do: []

  defp slugify(t), do: t |> String.downcase() |> String.replace(~r/[^a-z0-9\s-]/, "") |> String.replace(~r/\s+/, "-")

  defp md_to_html(c), do: case Earmark.as_html(c), do: ({:ok, h, _} -> h; {:error, h, _} -> h)

  defp org_to_html(c) do
    c
    |> String.split("\n")
    |> Enum.map(fn line ->
      cond do
        Regex.match?(~r/^\*{1}\s+(.*)$/, line) -> "<h1>#{org_inline(Regex.replace(~r/^\*+\s*/, line, ""))}</h1>"
        Regex.match?(~r/^\*{2}\s+(.*)$/, line) -> "<h2>#{org_inline(Regex.replace(~r/^\*+\s*/, line, ""))}</h2>"
        Regex.match?(~r/^\*{3}\s+(.*)$/, line) -> "<h3>#{org_inline(Regex.replace(~r/^\*+\s*/, line, ""))}</h3>"
        Regex.match?(~r/^\s*[-+]\s+(.*)$/, line) -> "<li>#{org_inline(Regex.replace(~r/^\s*[-+]\s*/, line, ""))}</li>"
        String.trim(line) == "" -> ""
        true -> "<p>#{org_inline(line)}</p>"
      end
    end)
    |> Enum.join("\n")
  end

  defp org_inline(t) do
    t
    |> String.replace(~r/\*([^\*]+)\*/, "<strong>\\1</strong>")
    |> String.replace(~r/\/([^\/]+)\//, "<em>\\1</em>")
    |> String.replace(~r/[=~]([^=~]+)[=~]/, "<code>\\1</code>")
    |> String.replace(~r/\[\[([^\]]+)\]\[([^\]]+)\]\]/, "<a href=\"\\1\">\\2</a>")
    |> String.replace(~r/\[\[([^\]]+)\]\]/, "<a href=\"\\1\">\\1</a>")
  end
end
