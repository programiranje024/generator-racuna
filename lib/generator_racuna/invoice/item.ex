defmodule GeneratorRacuna.Invoice.Item do
  @moduledoc """
  A single item on an invoice.
  """

  defstruct [:name, :price]

  def create(name, price) do
    %__MODULE__{name: name, price: price}
  end

  def render(item) do
    "#{item.name} - #{item.price} RSD"
  end
end
