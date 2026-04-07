defmodule Blog.Renderer do
  def render_post(post, config) do
    """
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>#{esc(post.title)} - #{esc(config.title)}</title>
      <link rel="stylesheet" href="../style.css">
      <link rel="alternate" type="application/rss+xml" title="RSS" href="../feed.xml">
    </head>
    <body>
      <header>
        <nav><a href="../index.html">← #{esc(config.title)}</a> <a href="../feed.xml">[RSS]</a></nav>
      </header>
      <main>
        <article>
          <header>
            <h1>#{esc(post.title)}</h1>
            <time datetime="#{post.date}">#{Calendar.strftime(post.date, "%B %d, %Y")}</time>
          </header>
          <div class="content">#{post.html}</div>
        </article>
      </main>
      <footer><p>#{esc(config.author)}</p></footer>
    </body>
    </html>
    """
  end

  def render_index(posts, config) do
    items = posts |> Enum.map(fn p ->
      "<li><time>#{p.date}</time> <a href=\"posts/#{p.slug}.html\">#{esc(p.title)}</a></li>"
    end) |> Enum.join("\n")

    """
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>#{esc(config.title)}</title>
      <link rel="stylesheet" href="style.css">
      <link rel="alternate" type="application/rss+xml" title="RSS" href="feed.xml">
    </head>
    <body>
      <header>
        <h1>#{esc(config.title)}</h1>
        <p>#{esc(config.description)}</p>
        <nav><a href="feed.xml">[RSS]</a></nav>
      </header>
      <main><section class="posts"><h2>Posts</h2><ul>#{items}</ul></section></main>
      <footer><p>#{esc(config.author)}</p></footer>
    </body>
    </html>
    """
  end

  defp esc(nil), do: ""
  defp esc(t) when is_binary(t), do: t |> String.replace("&", "&amp;") |> String.replace("<", "&lt;") |> String.replace(">", "&gt;")
  defp esc(t), do: esc(to_string(t))

  def css do
    """
    :root { --bg: #fff; --fg: #222; --link: #00e; --code-bg: #f5f5f5; --border: #ccc; }
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
    """
  end
end
