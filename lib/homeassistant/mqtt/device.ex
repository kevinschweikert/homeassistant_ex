defmodule Homeassistant.MQTT.Device do
  @moduledoc """
  A device struct
  """

  @typedoc ~S|A list of connections of the device to the outside world. For example the MAC address of a network interface: ["mac", "02:5b:26:a8:dc:12"]|
  @type connection :: [connection_type :: String.t(), connection_identifier :: String.t()]

  @type t() :: %__MODULE__{
          configuration_url: String.t(),
          connections: [connection()],
          hw_version: String.t(),
          identifiers: String.t() | [String.t()],
          manufacturer: String.t(),
          model: String.t(),
          model_id: String.t(),
          name: String.t(),
          serial_number: String.t(),
          suggested_area: String.t(),
          sw_version: String.t(),
          via_device: String.t()
        }

  @derive Jason.Encoder
  @enforce_keys [:identifiers]
  defstruct [
    :configuration_url,
    :connections,
    :hw_version,
    :identifiers,
    :manufacturer,
    :model,
    :model_id,
    :name,
    :serial_number,
    :suggested_area,
    :sw_version,
    :via_device
  ]

  defimpl Jason.Encoder do
    def encode(value, opts) do
      value
      |> Map.from_struct()
      |> Map.reject(fn {k, v} -> k not in @enforce_keys and is_nil(v) end)
      |> Jason.Encode.map(opts)
    end
  end
end
