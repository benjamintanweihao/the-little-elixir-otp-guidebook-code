defmodule MeterToLengthConverter do
  defmodule Feet do
    def convert(m) do
      m * 3.28084
    end  
  end
  
  defmodule Inch do
    def convert(m) do
      m * 39.3701
    end  
  end
end

