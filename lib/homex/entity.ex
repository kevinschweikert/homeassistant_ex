defmodule Homex.Entity do
  @moduledoc """
  Defines the behaviour and struct for an entity implementation
  """

  @doc "The given name of the entity"
  @callback name() :: String.t()

  @doc "The unique id of the entity"
  @callback unique_id() :: String.t()

  @doc "The list of topics to subscribe to"
  @callback subscriptions() :: [String.t()]

  @doc "The Home Assistant component config definition"
  @callback config() :: map()

  @doc "The Home Assistant platform"
  @callback platform() :: String.t()

  @doc false
  @callback setup_entity(t()) :: t()

  @doc """
  Configures the intial state for the switch
  """
  @callback handle_init(entity :: t()) :: entity :: t()

  @doc """
  Handle a new message from the subscriptions
  """
  @callback handle_message({topic :: String.t(), payload :: term()}, entity :: t()) ::
              entity :: t()

  @doc """
  If an `update_interval` is set, this callback will be fired
  """
  @callback handle_timer(entity :: Entity.t()) :: entity :: t()

  @type t() :: %__MODULE__{
          keys: MapSet.t(),
          values: map(),
          handlers: map(),
          changes: map(),
          private: map()
        }

  defstruct values: %{}, changes: %{}, handlers: %{}, keys: MapSet.new(), private: %{}

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts], generated: true do
      import Homex.Entity
      alias Homex.Entity
      @behaviour Homex.Entity

      @update_interval opts[:update_interval]

      use GenServer

      def start_link(init_arg), do: GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)

      @impl GenServer
      def init(_init_arg \\ []) do
        case @update_interval do
          :never -> :ok
          time -> :timer.send_interval(time, :update)
        end

        {:ok, Entity.new() |> setup_entity() |> handle_init() |> Entity.execute_change(),
         {:continue, :register}}
      end

      @impl GenServer
      def handle_continue(:register, entity) do
        Process.flag(:trap_exit, true)

        for topic <- subscriptions() do
          Registry.register(Homex.SubscriptionRegistry, topic, nil)
        end

        {:noreply, entity}
      end

      @impl GenServer
      def handle_info({topic, payload}, entity) do
        {:noreply, handle_message({topic, payload}, entity) |> Entity.execute_change()}
      end

      def handle_info(:update, entity) do
        {:noreply,
         entity
         |> handle_timer()
         |> Entity.execute_change()}
      end

      @impl GenServer
      def terminate(_reason, entity) do
        for topic <- subscriptions() do
          Registry.unregister(Homex.SubscriptionRegistry, topic)
        end
      end

      @impl Homex.Entity
      def setup_entity(entity), do: entity

      @impl Homex.Entity
      def handle_init(entity), do: entity

      @impl Homex.Entity
      def handle_message({_topic, _payload}, entity), do: entity

      @impl Homex.Entity
      def handle_timer(entity), do: entity

      defoverridable setup_entity: 1, handle_init: 1, handle_timer: 1, handle_message: 2
    end
  end

  @doc false
  @spec new() :: t()
  def new, do: %__MODULE__{}

  @doc false
  @spec register_handler(t(), atom(), fun(), term()) :: t()
  def register_handler(
        %__MODULE__{keys: keys, values: values, handlers: handlers} = entity,
        key,
        handler_fn,
        initial_value \\ nil
      )
      when is_atom(key) and is_function(handler_fn) do
    values = Map.put(values, key, initial_value)
    handlers = Map.put(handlers, key, handler_fn)
    keys = MapSet.put(keys, key)

    %{entity | keys: keys, values: values, handlers: handlers}
  end

  @doc false
  @spec put_change(t(), atom(), term()) :: t()
  def put_change(%__MODULE__{keys: keys, changes: changes} = entity, key, value)
      when is_atom(key) do
    if key in keys do
      changes = Map.put(changes, key, value)
      %{entity | changes: changes}
    else
      entity
    end
  end

  @doc false
  @spec execute_change(t()) :: t()
  def execute_change(
        %__MODULE__{keys: keys, values: values, changes: changes, handlers: handlers} = entity
      ) do
    values =
      for key <- keys, into: %{} do
        value = Map.get(values, key)
        change = Map.get(changes, key)
        handler = Map.get(handlers, key)

        if value != change and not is_nil(change) do
          handler.(change)
        end

        {key, change}
      end

    %{entity | changes: %{}, values: values}
  end

  @doc """
  Puts a value into the Entity struct to retrieve it later. Can be used as a key-value store for user data
  """
  @spec put_private(t(), atom(), term()) :: t()
  def put_private(%__MODULE__{private: private} = entity, key, value) when is_atom(key) do
    private = Map.put(private, key, value)
    %{entity | private: private}
  end

  @doc """
  Gets the value from the Entity struct
  """
  @spec get_private(t(), atom()) :: term()
  def get_private(%__MODULE__{private: private}, key) when is_atom(key) do
    Map.get(private, key)
  end

  @doc """
  Checks if the given module implements the behaviour from this module
  """
  @spec implements_behaviour?(atom()) :: boolean()
  def implements_behaviour?(module) when is_atom(module) do
    attrs = module.__info__(:attributes) |> Keyword.get_values(:behaviour) |> List.flatten()
    __MODULE__ in attrs
  end
end
