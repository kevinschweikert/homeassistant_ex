defmodule Homeassistant do
  @moduledoc """
  Documentation for `Homeassistant`.

  ## Example 

  ```elixir
  defmodule MyApp.Homeassistant do
    use Homeassistant, host: "localhost", username: "foo", password: "bar"
  end
  ```

  Put it in you application tree like

  ```elixir
  children = [
    ...
    MyApp.Homeassistant,
    ...
  ]
  """

  # FIXME: read from application config to supply credentials not only at compile time
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @defaults [
        name: __MODULE__,
        host: "localhost",
        port: 1883,
        username: "admin",
        password: "admin"
      ]

      def child_spec(opts) do
        opts = Keyword.merge(opts, @defaults)

        %{
          id: :emqtt,
          start: {:emqtt, :start_link, [opts]}
        }
      end
    end
  end
end
