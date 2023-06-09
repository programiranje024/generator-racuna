defmodule GeneratorRacunaWeb.PageLive do
  alias GeneratorRacuna.Invoice
  alias GeneratorRacuna.Invoice.Item
  use GeneratorRacunaWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, items: [])}
  end

  def handle_event(
        "handle_form",
        %{"submit" => action} = params,
        socket
      ) do
    case action do
      "add_item" -> handle_add_item(socket, params)
      "generate_pdf" -> handle_generate_pdf(socket, params)
    end
  end

  def handle_event("remove_item", %{"idx" => idx}, socket) do
    {:noreply,
     assign(socket, items: List.delete_at(socket.assigns.items, String.to_integer(idx)))
     |> put_flash(:info, "Stavka uspešno obrisana")}
  end

  def render(assigns) do
    assigns = assign(assigns, :no_items, assigns.items == [])

    assigns =
      assign(
        assigns,
        :total,
        if assigns.no_items do
          0.0
        else
          Enum.sum(Enum.map(assigns.items, & &1.price))
        end
      )

    assigns = assign(assigns, :total, :erlang.float_to_binary(assigns.total, decimals: 2))

    ~H"""
    <div class="grid grid-cols-2 gap-4">
      <form
        id="form"
        class="form"
        phx-submit="handle_form"
        phx-update={if !@no_items, do: "ignore", else: "replace"}
      >
        <h1 class="text-3xl mb-3">Račun</h1>

        <div class="form-group" data-hidden={@no_items}>
          <label for="name">Ime klijenta</label>
          <input type="text" id="name" name="name" placeholder="Ime klijenta..." />
        </div>

        <hr data-hidden={@no_items} />

        <div class="form-group" data-hidden={@no_items}>
          <label for="date">Datum</label>
          <input type="date" id="date" name="date" value={Date.utc_today()} />
        </div>

        <div class="form-group" data-hidden={@no_items}>
          <label for="due_date">Rok plaćanja</label>
          <input type="date" id="due_date" name="due_date" />
        </div>

        <hr data-hidden={@no_items} />

        <div class="form-group">
          <label for="service">Vrsta stavke</label>
          <select id="service" name="service" required={@no_items}>
            <option value="tariff">Tarifa</option>
            <option value="discount">Popust</option>
            <option value="separator" disabled><%= String.duplicate("-", 20) %></option>
            <option value="tutoring">Privatni čas</option>
            <option value="course">Kurs</option>
            <option value="project">Izrada projekta</option>
          </select>
        </div>

        <div class="form-group">
          <label for="description">Opis usluge</label>
          <textarea
            id="description"
            name="description"
            placeholder="Opis usluge..."
            required={@no_items}
          >
          </textarea>
        </div>

        <div class="form-group">
          <label for="price">Cena</label>
          <input type="number" id="price" name="price" placeholder="Cena..." required={@no_items} />
        </div>

        <div class="flex gap-2">
          <button
            class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
            name="submit"
            value="add_item"
            type="submit"
          >
            Dodaj stavku
          </button>
          <button
            class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:bg-blue-500"
            type="submit"
            name="submit"
            value="generate_pdf"
            disabled={@no_items}
          >
            Generiši PDF
          </button>
        </div>
      </form>

      <div class="flex flex-col">
        <h1 class="text-3xl mb-3">Stavke</h1>
        <div class="flex flex-col gap-2">
          <%= if @items == [] do %>
            <div class="flex justify-between">
              <p class="text-gray-400">Trenutno nema stavki.</p>
            </div>
          <% else %>
            <%= for {item, idx} <- Enum.with_index(@items) do %>
              <div
                class="flex justify-between border-b-2 hover:bg-gray-100 hover:cursor-pointer"
                phx-click="remove_item"
                phx-value-idx={idx}
              >
                <div class="flex gap-2">
                  <div><%= Item.type_to_string(item.service) %>:</div>
                  <div><%= item.description %></div>
                </div>
                <div><%= :erlang.float_to_binary(item.price, decimals: 2) %> RSD</div>
              </div>
            <% end %>
            <div class="flex justify-between">
              <div class="font-bold">Ukupno:</div>
              <div class="font-bold">
                <%= @total %> RSD
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp string_not_empty(string, name) do
    case String.trim(string) do
      "" -> {:error, name}
      _ -> {:ok, string}
    end
  end

  defp handle_add_item(
         socket,
         %{"service" => service, "description" => description, "price" => price}
       ) do
    with {:ok, price} <- string_not_empty(price, "Cena"),
         {:ok, service} <- string_not_empty(service, "Tip usluge"),
         {:ok, description} <- string_not_empty(description, "Opis usluge"),
         {price, ""} <- Float.parse(price) do
      {:noreply,
       assign(socket,
         items:
           socket.assigns.items ++
             [%{service: service, description: description, price: price}]
       )
       |> put_flash(:info, "Stavka uspešno dodata")
       |> push_event("clear-item-form", %{})}
    else
      :error -> {:noreply, socket |> put_flash(:error, "Cena mora biti broj")}
      {:error, "Cena"} -> {:noreply, socket |> put_flash(:error, "Cena ne sme biti prazna")}
      {:error, string} -> {:noreply, socket |> put_flash(:error, "#{string} ne sme biti prazan")}
    end
  end

  defp handle_generate_pdf(socket, %{
         "name" => name,
         "date" => date,
         "due_date" => due_date
       }) do
    with {:ok, name} <- string_not_empty(name, "Ime klijenta"),
         {:ok, date} <- string_not_empty(date, "Datum"),
         {:ok, due_date} <- string_not_empty(due_date, "Rok plaćanja"),
         {:ok, {date, due_date}} <- validate_dates(date, due_date),
         items <-
           Enum.map(socket.assigns.items, fn item ->
             Item.create("#{Item.type_to_string(item.service)}: #{item.description}", item.price)
           end),
         invoice <- Invoice.create(name, date, due_date, items),
         html <- Invoice.render(invoice),
         filename <- generate_filename(),
         {:ok, content} <-
           PdfGenerator.generate_binary(html,
             page_size: "A5",
             shell_params: ["--encoding", "utf-8"]
           ),
         :ok <- File.write("priv/static/generated/#{filename}", content) do
      {:noreply,
       socket
       |> put_flash(
         :info,
         "PDF uspešno generisan!"
       )
       |> push_event("download", %{"url" => "/generated/#{filename}"})}
    else
      {:error, :date} ->
        {:noreply, socket |> put_flash(:error, "Datum ne sme biti posle roka plaćanja")}

      {:error, "Ime klijenta"} ->
        {:noreply, socket |> put_flash(:error, "Ime klijenta ne sme biti prazno")}

      {:error, string} ->
        {:noreply, socket |> put_flash(:error, "#{string} ne sme biti prazan")}

      _error ->
        {:noreply, socket |> put_flash(:error, "Došlo je do greške prilikom generisanja PDF-a")}
    end
  end

  defp generate_filename do
    "invoice_#{DateTime.utc_now() |> DateTime.to_unix()}.pdf"
  end

  defp validate_dates(date, due_date) do
    with {:ok, date_n} <- Date.from_iso8601(date),
         {:ok, due_date_n} <- Date.from_iso8601(due_date),
         true <- Date.compare(date_n, due_date_n) in [:lt, :eq] do
      {:ok, {date, due_date}}
    else
      :gt -> {:error, :date}
      _error -> :error
    end
  end
end
