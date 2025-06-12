defmodule Homeassistant.MQTT do
  @moduledoc """
  The base struct for the discovery packet
  """

  alias Homeassistant.MQTT.Device
  alias Homeassistant.MQTT.Origin
  alias Homeassistant.MQTT.Component

  @type t() :: %__MODULE__{
          device: Device.t(),
          origin: Origin.t(),
          components: %{optional(String.t()) => Component.t()},
          availability: Availability.t(),
          state_topic: String.t(),
          command_topic: String.t(),
          qos: pos_integer(),
          encoding: String.t()
        }

  @derive Jason.Encoder

  defstruct [
    :device,
    :origin,
    :availability,
    :components,
    :state_topic,
    :command_topic,
    :qos,
    encoding: "utf-8"
  ]
end
