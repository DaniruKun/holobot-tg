defmodule Holobot.Telegram.Commands do
  @moduledoc """
  Commands handler module.
  """
  use Holobot.Telegram.Commander
  use Holobot.Telegram.Router

  alias Holobot.Telegram.Commands
  alias Holobot.Telegram.Commands.Inline

  require Logger

  command("start") do
    Logger.info("Command /start")

    send_message("A-Chan bot started! Type `/help` to learn more.", [{:parse_mode, "Markdown"}])
  end

  command("help") do
    Logger.info("Command /help")

    send_message(Holobot.Telegram.Messages.build_help_msg(), [{:parse_mode, "Markdown"}])
  end

  command("streams", Commands.Streams, :streams)

  callback_query_command("streams", Commands.Streams, :streams_query_command)

  command("channels", Commands.Channels, :channels)

  callback_query_command("channels", Commands.Channels, :channels_query_command)

  command("ask", Commands.Ask, :ask)

  callback_query_command("ask", Commands.Ask, :ask_query_command)

  command("commands") do
    available_commands = """
    List of available commands:

    /streams - Get a list of live streams interactively
    /channels - Get a list of channels interactively
    /commands - Shows this list of commands
    /ask - Ask A-Chan a common question about Hololive
    /start - Starts the bot
    /help - Get info about A-Chan

    You can make inline queries by typing @a_chan_bot query/command

    E.g. to search by channels, type @a_chan_bot /channels query
    """

    send_message(available_commands)
  end

  inline_query_command("live", Inline.Live, :live)

  inline_query_command("channels", Inline.Channels, :channels)

  # Advanced Stuff
  #
  # Now that you already know basically how this boilerplate works let me
  # introduce you to a cool feature that happens under the hood.
  #
  # If you are used to telegram bot API, you should know that there's more
  # than one path to fetch the current message chat ID so you could answer it.
  # With that in mind and backed upon the neat macro system and the cool
  # pattern matching of Elixir, this boilerplate automatically detectes whether
  # the current message is a `inline_query`, `callback_query` or a plain chat
  # `message` and handles the current case of the Nadia method you're trying to
  # use.
  #
  # If you search for `defmacro send_message` at App.Commander, you'll see an
  # example of what I'm talking about. It just works! It basically means:
  # When you are with a callback query message, when you use `send_message` it
  # will know exatcly where to find it's chat ID. Same goes for the other kinds.

  inline_query_command "foo" do
    Logger.log(:info, "Inline Query Command /foo")
    # Where do you think the message will go for?
    # If you answered that it goes to the user private chat with this bot,
    # you're right. Since inline querys can't receive nothing other than
    # Nadia.InlineQueryResult models. Telegram bot API could be tricky.
    send_message("This came from an inline query")
  end

  # Fallbacks

  # Rescues any unmatched callback query.
  callback_query do
    Logger.log(:warn, "Did not match any callback query")

    # answer_callback_query(text: "Sorry, but there is no JoJo better than Joseph.")
  end

  # Rescues any unmatched inline query, will perform query search across Holofans API.
  inline_query(Inline.Search, :search)

  # Fallback message handler.
  message(Commands.Other, :other)
end
