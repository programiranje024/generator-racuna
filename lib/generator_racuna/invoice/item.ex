defmodule GeneratorRacuna.Invoice.Item do
  @moduledoc """
  A single item on an invoice.
  """

  defstruct [:name, :price]

  def create(name, price) do
    %__MODULE__{name: name, price: price}
  end

  def type_to_string(type) do
    case type do
      "tutoring" -> "Privatni čas"
      "course" -> "Kurs"
      "project" -> "Izrada projekta"
      "tariff" -> "Tarifa"
      "discount" -> "Popust"
    end
  end
end
