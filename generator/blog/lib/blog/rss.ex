defmodule Blog.RSS do
  def generate(posts, config) do
    items = posts |> Enum.take(20) |> Enum.map(&item(&1, config)) |> Enum.join("\n")
    now = DateTime.utc_now()
    build_date = Calendar.strftime(now, "%a, %d %b %Y %H:%M:%S +0000")
    author = Map.get(config, :author, config.title)
    """
    <?xml version="1.0" encoding="UTF-8"?>
    <rss version="2.0"
      xmlns:atom="http://www.w3.org/2005/Atom"
      xmlns:dc="http://purl.org/dc/elements/1.1/">
      <channel>
        <title>#{esc(config.title)}</title>
        <link>#{esc(config.url)}</link>
        <description>#{esc(config.description)}</description>
        <language>en</language>
        <copyright>Copyright #{now.year} #{esc(author)}</copyright>
        <lastBuildDate>#{build_date}</lastBuildDate>
        <atom:link href="#{config.url}/feed.xml" rel="self" type="application/rss+xml"/>
        #{items}
      </channel>
    </rss>
    """
  end

  defp item(post, config) do
    date = post.date |> Date.to_erl() |> then(&{&1, {12,0,0}}) |> NaiveDateTime.from_erl!() |> DateTime.from_naive!("Etc/UTC")
    author = Map.get(config, :author, config.title)
    """
    <item>
      <title><![CDATA[#{post.title}]]></title>
      <link>#{config.url}/posts/#{post.slug}.html</link>
      <guid>#{config.url}/posts/#{post.slug}.html</guid>
      <pubDate>#{Calendar.strftime(date, "%a, %d %b %Y %H:%M:%S +0000")}</pubDate>
      <dc:creator>#{esc(author)}</dc:creator>
      <description><![CDATA[#{post.html}]]></description>
    </item>
    """
  end

  defp esc(nil), do: ""
  defp esc(t) when is_binary(t), do: t |> String.replace("&", "&amp;") |> String.replace("<", "&lt;") |> String.replace(">", "&gt;")
  defp esc(t), do: esc(to_string(t))
end
