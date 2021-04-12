defmodule Holobot.Application do
  @moduledoc false
  require Logger
  require Nadia

  use Application

  def start(_type, _args) do
    bot_name = Application.fetch_env!(:holobot, :bot_name)

    validate_bot_name(bot_name)

    children = [
      # Start caching servers
      {Holobot.Holofans.Videos, []},
      {Holobot.Holofans.Channels, []},
      # Start Telegram API poller
      {Holobot.Telegram.Poller, []},
      # Start matcher
      {Holobot.Telegram.Matcher, []}
    ]

    HTTPoison.start()

    opts = [strategy: :one_for_one, name: Holobot.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp validate_bot_name(bot_name) do
    unless String.valid?(bot_name) do
      IO.warn("""
      Env not found Application.get_env(:holobot, :bot_name)
      This will give issues when generating commands
      """)
    end

    if bot_name == "" do
      IO.warn("An empty bot_name env will make '/anycommand@' valid")
    end
  end
end
