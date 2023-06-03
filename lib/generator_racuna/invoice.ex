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
    """
    <html>
      <head>
        <title>#{name}</title>
        <style>
          #{get_css()}
        </style>
      </head>
      <body>
        <h1>Programiranje 024</h1>
        <h3>Mušterija: #{name}</h3>
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
          <p>#{Enum.sum(Enum.map(items, & &1.price))} RSD</p>
        </div>
      </body>
    """
  end

  defp render_items(items) do
    Enum.map(items, fn item ->
      """
      <tr>
        <td>#{item.name}</td>
        <td>#{item.price} RSD</td>
      </tr>
      """
    end)
  end

  defp get_css() do
    """
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
