defmodule HelpersTest do
  @moduledoc false
  use ExUnit.Case, async: true

  import Mock

  alias Holobot.Helpers
  alias Holobot.Holofans.Channel
  alias Holobot.Holofans.Video

  @valid_channel %Channel{
    name: "Watson Amelia Ch. hololive-EN",
    yt_channel_id: "UCyl1z3jo3XHR1riLFKG5UAg"
  }

  @valid_video %Video{
    yt_video_key: "somevideokey",
    live_start: "sometime",
    channel: "somechannel"
  }

  defp channel_fixture(attrs \\ %{}) do
    Map.merge(@valid_channel, attrs)
  end

  describe "channel emojis" do
    test "get_channel_emoji/1 returns the correct YT channel emoji when channel is matched" do
      channel = channel_fixture()

      assert "🔎" = Helpers.get_channel_emoji(channel.yt_channel_id)
    end

    test "get_chanel_emoji/1 returns empty binary when YT channel is not found" do
      channel = channel_fixture(%{yt_channel_id: "some_fake_id"})

      assert "" = Helpers.get_channel_emoji(channel.yt_channel_id)
    end
  end

  describe "tokenizer" do
    test "tokenize_msg/1 returns correct tokens for message with punctuation and multiple words" do
      msg_text = "How are you doing?"

      assert ["how", "are", "you", "doing"] = Helpers.tokenize_msg(msg_text)
    end
  end

  describe "golive push" do
    test "send_golive_push/1 returns an ok response if push to webhook is succesful" do
      with_mock HTTPoison, post: fn url, data, headers -> {:ok, "ok_resp"} end do
        assert ["ok_resp"] = Helpers.send_golive_push!(@valid_video)
      end
    end
  end
end
