defmodule Homeassistant.Entity.Switch do
  @moduledoc """
  https://www.home-assistant.io/integrations/switch.mqtt
  """
  alias Homeassistant.Entity

  @behaviour Entity

  @enforce_keys [:name]
  defstruct [
    :device_class,
    :enabled_by_default,
    :entity_category,
    :entity_picture,
    :icon,
    :name,
    :qos,
    :retain
  ]

  @impl Entity
  def configuration(%__MODULE__{} = switch) do
    internal = %{
      platform: "switch",
      command_topic: command_topic(switch),
      state_topic: state_topic(switch),
      unique_id: unique_id(switch)
    }

    switch
    |> Map.from_struct()
    |> Map.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.merge(internal)
  end

  def set_state(%__MODULE__{} = switch, state) when is_boolean(state) do
    payload = if state, do: "ON", else: "OFF"
    topic = state_topic(switch)
    Homeassistant.Client.publish(topic, payload)
  end

  def subscribe(%__MODULE__{} = switch) do
    topic = command_topic(switch)
    Homeassistant.Client.subscribe(topic)
  end

  defp command_topic(%__MODULE__{name: name}) do
    # TODO: make discovery topic configurable
    "homeassistant/switch/#{entity_id(name)}/set"
  end

  defp state_topic(%__MODULE__{name: name}) do
    # TODO: make discovery topic configurable
    "homeassistant/switch/#{entity_id(name)}/set"
  end

  defp unique_id(%__MODULE__{name: name}) do
    "#{entity_id(name)}_#{:erlang.phash2(name)}"
  end

  defp entity_id(%__MODULE__{name: name}) when is_binary(name) do
    name
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9_]/, "_")
  end
end
