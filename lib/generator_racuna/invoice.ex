defmodule GeneratorRacuna.Invoice do
  @moduledoc """
  A struct representing an invoice.
  """

  defstruct [
    :name,
    :date,
    :due_date,
    :items
  ]

  def create(name, date, due_date, items) do
    %__MODULE__{
      name: name,
      date: date,
      due_date: due_date,
      items: items
    }
  end

  def render(%__MODULE__{name: name, date: date, due_date: due_date, items: items}) do
    with {:ok, path} <- File.cwd(),
         image_path = Path.join(path, "/priv/static/images/logo.png") do
      """
      <html>
      <head>
        <title>#{name}</title>
        <style>
          #{get_css()}
        </style>
      </head>
      <body>
        <img src="#{get_image_base64(image_path, "image/png")}" alt="Logo" height="100">
        <h3>Klijent: #{name}</h3>
        <p class="m0"><span class="bold">Datum:</span> #{format_date(date)}</p>
        <p class="m0"><span class="bold">Rok plaćanja:</span> #{format_date(due_date)}</p>
        <table>
          <thead>
            <tr>
              <th>Stavka</th>
              <th>Cena</th>
            </tr>
          </thead>
          <tbody>
            #{render_items(items)}
          </tbody>
        </table>
        <div class='total'>
          <p class="bold">Ukupna cena:</p>
          <p>#{:erlang.float_to_binary(Enum.sum(Enum.map(items, & &1.price)), decimals: 2)} RSD</p>
        </div>
      </body>
      """
    else
      _error -> "Failed to render invoice"
    end
  end

  defp render_items(items) do
    Enum.map(items, fn item ->
      """
      <tr>
        <td>#{item.name}</td>
        <td>#{:erlang.float_to_binary(item.price, decimals: 2)} RSD</td>
      </tr>
      """
    end)
  end

  defp get_image_base64(path, mime) do
    with {:ok, content} <- File.read(path),
         base64 <- Base.encode64(content) do
      "data:#{mime};base64,#{base64}"
    else
      _error -> "Failed to read image"
    end
  end

  defp get_css() do
    """
    img {
      display: block;
      margin: 0 auto;
    }

    .m0 {
      margin: 0;
    }

    .total {
      display: -webkit-box;
      -webkit-box-pack: justify;
    }

    .bold {
      font-weight: bold;
    }

    table {
      width: 100%;
      border-collapse: collapse;
      margin-top: 10px;
    }

    th,
    tr:nth-child(even) {
      background-color: #1c1c1c;
      color: #f2f2f2;
    }

    th:first-child,
    tr:nth-child(even) td:first-child {
      border-right-color: #f2f2f2;
    }

    table, th, td {
      padding: 5px;
      border: 1px solid black;
    }

    td,
    th {
      text-align: left;
    }

    th:last-child,
    td:last-child {
      text-align: right;
    }
    """
  end

  defp format_date(date) do
    [year, month, day] = String.split(date, "-")
    "#{day}/#{month}/#{year}"
  end
end
