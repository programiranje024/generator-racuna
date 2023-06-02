defmodule GeneratorRacuna.Invoice do
  @moduledoc """
  A struct representing an invoice.
  """
  alias GeneratorRacuna.Invoice.Item

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
      </head>
      <body>
        <h1>#{name}</h1>
        <p>#{date}</p>
        <p>#{due_date}</p>
        <table>
          <thead>
            <tr>
              <th>Item</th>
              <th>Price</th>
            </tr>
          </thead>
          <tbody>
            #{render_items(items)}
          </tbody>
        </table>
      </body>
    """
  end

  defp render_items(items) do
    Enum.map(items, fn item ->
      Item.render(item)
    end)
  end
end
