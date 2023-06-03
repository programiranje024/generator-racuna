defmodule GeneratorRacunaWeb.PageLive do
  alias GeneratorRacuna.Invoice
  alias GeneratorRacuna.Invoice.Item
  use GeneratorRacunaWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket, items: [%{service: "tutoring", description: "Opis usluge", price: 1000}])}
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

    ~H"""
    <div class="grid grid-cols-2 gap-4">
      <form class="form" phx-submit="handle_form" action="#">
        <h1 class="text-3xl mb-3">Račun</h1>

        <div class="form-group">
          <label for="name">Ime klijenta</label>
          <input type="text" id="name" name="name" placeholder="Ime klijenta..." required />
        </div>

        <hr />

        <div class="form-group">
          <label for="date">Datum</label>
          <input type="date" id="date" name="date" required />
        </div>

        <div class="form-group">
          <label for="due_date">Rok plaćanja</label>
          <input type="date" id="due_date" name="due_date" required />
        </div>

        <hr />

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
                  <div><%= service_to_string(item.service) %>:</div>
                  <div><%= item.description %></div>
                </div>
                <div><%= item.price %> RSD</div>
              </div>
            <% end %>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp service_to_string(service) do
    case service do
      "tutoring" -> "Privatni čas"
      "course" -> "Kurs"
      "project" -> "Izrada projekta"
      "tariff" -> "Tarifa"
      "discount" -> "Popust"
    end
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
    with {:ok, price} <- string_not_empty(price, "Broj cene"),
         {:ok, service} <- string_not_empty(service, "Tip usluge"),
         {:ok, description} <- string_not_empty(description, "Opis usluge"),
         {price, ""} <- Float.parse(price) do
      {:noreply,
       assign(socket,
         items:
           socket.assigns.items ++ [%{service: service, description: description, price: price}]
       )
       |> put_flash(:info, "Stavka uspešno dodata")}
    else
      :error -> {:noreply, socket |> put_flash(:error, "Cena mora biti broj")}
      {:error, string} -> {:noreply, socket |> put_flash(:error, "#{string} ne sme biti prazan")}
    end
  end

  defp handle_generate_pdf(socket, %{
         "name" => name,
         "date" => date,
         "due_date" => due_date
       }) do
    with items <-
           Enum.map(socket.assigns.items, fn item ->
             Item.create("#{item.service}: #{item.description}", item.price)
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
      err ->
        IO.inspect(err)
        {:noreply, socket |> put_flash(:error, "Došlo je do greške prilikom generisanja PDF-a")}
    end
  end

  defp generate_filename do
    "invoice_#{DateTime.utc_now() |> DateTime.to_unix()}.pdf"
  end
end
