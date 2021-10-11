defmodule BowlingHouse.Frame do
  @enforce_keys [:first_throw_pins_hits]
  @derive Jason.Encoder
  @maximum_hits 10
  defstruct first_throw_pins_hits: 0, second_throw_pins_hits: nil, score: 0
  @type t :: %__MODULE__{}

  @spec strike?(BowlingHouse.Frame.t()) :: boolean
  def strike?(%__MODULE__{first_throw_pins_hits: @maximum_hits}), do: true
  def strike?(%__MODULE__{}), do: false

  @spec spare?(BowlingHouse.Frame.t()) :: boolean
  def spare?(%__MODULE__{first_throw_pins_hits: @maximum_hits}), do: false

  def spare?(%__MODULE__{first_throw_pins_hits: _first_hit, second_throw_pins_hits: nil}),
    do: false

  def spare?(%__MODULE__{first_throw_pins_hits: first_hits, second_throw_pins_hits: second_hits}) do
    first_hits + second_hits == @maximum_hits
  end

  @spec done?(BowlingHouse.Frame.t()) :: boolean
  def done?(%__MODULE__{} = frame) do
    strike?(frame) || spare?(frame) || !!frame.second_throw_pins_hits
  end

  @spec add_hits(BowlingHouse.Frame.t(), number) :: BowlingHouse.Frame.t()
  def add_hits(%__MODULE__{first_throw_pins_hits: first_hits} = frame, hits) do
    frame
    |> Map.put(:second_throw_pins_hits, hits)
    |> Map.put(:score, hits + first_hits)
  end

  @spec exceed_frame_limit?(BowlingHouse.Frame.t(), number) :: boolean
  def exceed_frame_limit?(%__MODULE__{first_throw_pins_hits: first_hits}, hits) do
    first_hits + hits > @maximum_hits
  end
end
