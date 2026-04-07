defmodule Blog.Parser do
  defstruct [:title, :slug, :date, :tags, :description, :content, :html]

  def parse_file(path) do
    case File.read(path) do
      {:ok, content} -> parse(content, path)
      _ -> nil
    end
  end

  defp parse(content, path) do
    case parse_frontmatter(content) do
      {fm, body} ->
        build_post(fm, body, md_to_html(body), path)
      nil -> nil
    end
  end

  defp parse_frontmatter(content) do
    if String.starts_with?(content, "---") do
      case Regex.run(~r/\A---\n(.*?)\n---\n(.*)/s, content) do
        [_, yaml, body] -> {YamlElixir.read_from_string!(yaml), body}
        _ -> nil
      end
    else
      nil
    end
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
  defp parse_date(d) when is_binary(d) do
    case Date.from_iso8601(d) do
      {:ok, d} -> d
      _ -> Date.utc_today()
    end
  end
  defp parse_date(d), do: d

  defp parse_tags(t) when is_list(t), do: t
  defp parse_tags(t) when is_binary(t), do: String.split(t, ",") |> Enum.map(&String.trim/1)
  defp parse_tags(_), do: []

  defp slugify(t), do: t |> String.downcase() |> String.replace(~r/[^a-z0-9\s-]/, "") |> String.replace(~r/\s+/, "-")

  defp md_to_html(c) do
    case Earmark.as_html(c) do
      {:ok, h, _} -> h
      {:error, h, _} -> h
    end
  end
end
