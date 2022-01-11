if Code.ensure_loaded?(Tesla) do
  defmodule PromEx.Plugins.Tesla do
    @moduledoc """
    This plugin captures metrics emitted by Tesla. Specifically, it captures HTTP request metrics.

    ## Plugin options

    This plugin supports the following options:
    - `metric_prefix`: This option is OPTIONAL and is used to override the default metric prefix of
    `[otp_app, :prom_ex, :tesla]`. If this changes you will also want to set `tesla_metric_prefix`
    in your `dashboard_assigns` to the snakecase version of your prefix, the default
    `telsa_metric_prefix` is `{otp_app}_prom_ex_tesla`.


    ## Usage

    To use plugin in your application, add the following to your PromEx module:
    """

    use PromEx.Plugin

    require Logger

    @stop_event [:tesla, :request, :stop]
    @error_event [:tesla, :request, :exception]

    @impl true
    def event_metrics(opts) do
      otp_app = Keyword.fetch!(opts, :otp_app)
      metric_prefix = Keyword.get(opts, :metric_prefix, PromEx.metric_prefix(otp_app, :tesla))

      # Event metrics definitions
      [
        http_events(metric_prefix, opts)
      ]
    end

    defp http_events(metric_prefix, _opts) do
      Event.build(
        :tesla_event_metrics,
        [
          distribution(
            metric_prefix ++ [:request, :duration, :milliseconds],
            event_name: @stop_event,
            measurement: :duration,
            description: "The time it takes for the client to receive HTTP responses.",
            reporter_options: [
              buckets: exponential!(1, 2, 12)
            ],
            tag_values: &tag_values/1,
            tags: [:method, :status, :template_url, :resolved_url, :error],
            unit: {:native, :millisecond}
          ),
          distribution(
            metric_prefix ++ [:request, :exception, :duration, :milliseconds],
            event_name: @error_event,
            measurement: :duration,
            description: "The time it takes for the client to receive HTTP responses that result in an exception.",
            reporter_options: [
              buckets: exponential!(1, 2, 12)
            ],
            tag_values: &tag_values/1,
            tags: [:method, :status, :template_url, :resolved_url, :error],
            unit: {:native, :millisecond}
          )
        ]
      )
    end

    defp tag_values(metadata) do
      # The meta.env.url key will only present the resolved URL on happy-path scenarios.
      # Error cases will still return the original template url.
      %{
        template_url: metadata.env.opts[:req_url],
        resolved_url: metadata.env.url,
        status: metadata.env.status,
        method: metadata.env.method,
        error: metadata[:error]
      }
    end
  end
else
  defmodule PromEx.Plugins.Tesla do
    @moduledoc false
    use PromEx.Plugin

    @impl true
    def event_metrics(_opts) do
      PromEx.Plugin.no_dep_raise(__MODULE__, "Tesla")
    end
  end
end
