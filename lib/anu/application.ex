defmodule Anu.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = finch_child_spec()

    opts = [strategy: :one_for_one, name: Anu.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp finch_child_spec do
    if Anu.Config.custom_finch?() do
      []
    else
      pool_opts = Anu.Config.finch_pool_opts()

      [
        {Finch,
         name: Anu.Finch,
         pools: %{
           "https://graph.facebook.com" => pool_opts
         }}
      ]
    end
  end
end
