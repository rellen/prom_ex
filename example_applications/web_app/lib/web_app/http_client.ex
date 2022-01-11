defmodule WebApp.HttpClient do
  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://localhost:4000"
  # plug Tesla.Middleware.Headers, [{"authorization", "token xyz"}]
  plug Tesla.Middleware.JSON
  plug Tesla.Middleware.KeepRequest
  plug Tesla.Middleware.Telemetry
  plug Tesla.Middleware.PathParams
  plug Tesla.Middleware.Logger

  def user(id) do
    params = [id: id]
    get("/userzs/:id", opts: [path_params: params])
  end
end
