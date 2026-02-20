defmodule EdmFestivalHubWeb.FormComponents do
  @moduledoc """
  Small, app-owned form components.

  Phoenix 1.8 adjusted generated core components; keeping our own tiny wrappers
  avoids coupling this project to a specific generator style.
  """

  use Phoenix.Component

  attr :field, Phoenix.HTML.FormField, required: true
  attr :type, :string, default: "text"
  attr :label, :string, default: nil
  attr :placeholder, :string, default: nil
  attr :required, :boolean, default: false
  attr :rest, :global, include: ~w(autocomplete disabled min max maxlength minlength pattern step)

  def input(assigns) do
    ~H"""
    <div class="form-control w-full">
      <label for={@field.id} class="label">
        <span class="label-text">{@label || Phoenix.Naming.humanize(@field.field)}</span>
      </label>

      <input
        type={@type}
        name={@field.name}
        id={@field.id}
        value={@field.value || ""}
        placeholder={@placeholder}
        required={@required}
        class={[
          "input input-bordered w-full",
          @field.errors != [] && "input-error"
        ]}
        {@rest}
      />

      <.errors :if={@field.errors != []} errors={@field.errors} />
    </div>
    """
  end

  attr :field, Phoenix.HTML.FormField, required: true
  attr :label, :string, default: nil
  attr :placeholder, :string, default: nil
  attr :required, :boolean, default: false
  attr :rows, :integer, default: 4
  attr :rest, :global, include: ~w(disabled maxlength minlength)

  def textarea(assigns) do
    ~H"""
    <div class="form-control w-full">
      <label for={@field.id} class="label">
        <span class="label-text">{@label || Phoenix.Naming.humanize(@field.field)}</span>
      </label>

      <textarea
        name={@field.name}
        id={@field.id}
        rows={@rows}
        placeholder={@placeholder}
        required={@required}
        class={[
          "textarea textarea-bordered w-full",
          @field.errors != [] && "textarea-error"
        ]}
        {@rest}
      ><%= @field.value || "" %></textarea>

      <.errors :if={@field.errors != []} errors={@field.errors} />
    </div>
    """
  end

  attr :type, :string, default: "submit"
  attr :class, :string, default: "btn btn-primary"
  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button type={@type} class={@class}>
      {render_slot(@inner_block)}
    </button>
    """
  end

  attr :errors, :list, required: true

  def errors(assigns) do
    ~H"""
    <div class="mt-1 space-y-1">
      <p :for={{msg, _opts} <- @errors} class="text-sm text-error">
        {msg}
      </p>
    </div>
    """
  end
end
