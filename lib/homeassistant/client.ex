defmodule Homeassistant.Client do
  @moduledoc """
  The MQTT client
  """

  # TODO: move to application config
  def name() do
    Homeassistant.EMQTT
  end

  def connect do
    :emqtt.connect(name())
  end

  def disconnect do
    :emqtt.disconnect(name())
  end

  def publish(topic, payload, opts \\ [])

  def publish(topic, payload, opts) when is_binary(payload) do
    :emqtt.publish(name(), topic, payload, opts)
  end

  def publish(topic, payload, opts) do
    with {:ok, data} <- Jason.encode(payload) do
      :emqtt.publish(name(), topic, data, opts)
    end
  end

  def subscribe(topic) do
    :emqtt.subscribe(name(), topic)
  end

  def unsubscribe(topic) do
    :emqtt.unsubscribe(name(), topic)
  end
end
