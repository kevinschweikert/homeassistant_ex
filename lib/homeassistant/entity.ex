defmodule Homeassistant.Entity do
  @moduledoc """
  A Homeassistant Entity
  """

  defstruct [:entity, :registry, :client]

  @callback configuration(entity :: term()) :: payload :: map()

  @callback subscriptions() :: [String.t()]

  @callback parse(payload :: String.t()) :: :ok | {:error, String.t()}

  use GenServer

  @impl GenServer
  def init(opts) do
    entity = Keyword.fetch!(opts, :entity)
    registry = Keyword.fetch!(opts, :registry)
    client = Keyword.fetch!(opts, :client)

    {:ok, %__MODULE__{entity: entity, registry: registry, client: client}}
  end
end
