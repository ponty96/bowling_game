defmodule BowlingHouse.FrameTest do
  use BowlingHouse.DataCase

  alias BowlingHouse.Frame

  test "strike?/1: it returns true when the struct first_throw_pins_hits value equals 10" do
    frame = %Frame{first_throw_pins_hits: 10}

    assert Frame.strike?(frame) == true
  end

  test "strike?/1: it returns false when the struct first_throw_pins_hits value less than 10" do
    hits = Enum.random(0..9)
    frame = %Frame{first_throw_pins_hits: hits}

    assert Frame.strike?(frame) == false
  end

  test "spare?/1: it returns true when the struct first_throw_pins_hits and second_throw_pins_hits value equals 10" do
    frame = %Frame{first_throw_pins_hits: 6, second_throw_pins_hits: 4}

    assert Frame.spare?(frame) == true
  end

  test "spare?/1: it returns false when the struct first_throw_pins_hits and second_throw_pins_hits value is less than 10" do
    frame = %Frame{first_throw_pins_hits: 2, second_throw_pins_hits: 3}

    assert Frame.spare?(frame) == false
  end

  test "done?/1: it returns true when the struct is a strike" do
    frame = %Frame{first_throw_pins_hits: 10}

    assert Frame.done?(frame) == true
  end

  test "done?/1: it returns true when the struct first_throw_pins_hits and second_throw_pins_hits value exist" do
    frame = %Frame{first_throw_pins_hits: 6, second_throw_pins_hits: 4}

    assert Frame.done?(frame) == true
  end

  test "done?/1: it returns false when the struct first_throw_pins_hits is less than 10 and second_throw_pins_hits value is nil" do
    frame = %Frame{first_throw_pins_hits: 2, second_throw_pins_hits: nil}

    assert Frame.done?(frame) == false
  end
end
