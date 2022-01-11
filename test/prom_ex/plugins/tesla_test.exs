defmodule PromEx.Plugins.TeslaTest do
  use ExUnit.Case, async: true

  alias PromEx.Plugins.Tesla, as: TeslaPlugin
  alias PromEx.Test.Support.{Events, Metrics}

  defmodule WebApp.PromEx do
    use PromEx, otp_app: :web_app

    @impl true
    def plugins do
      [PromEx.Plugins.Tesla]
    end
  end

  test "telemetry events are accumulated" do
    start_supervised!(WebApp.PromEx)

    Events.execute_all(:tesla)

    metrics =
      WebApp.PromEx
      |> PromEx.get_metrics()
      |> Metrics.sort()

    assert metrics == Metrics.read_expected(:tesla)
  end

  describe "event_metrics/1" do
    test "should return the correct number of metrics" do
      assert [_] = TeslaPlugin.event_metrics(otp_app: :prom_ex)
    end
  end
end
