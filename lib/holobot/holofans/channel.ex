defmodule Holobot.Holofans.Channel do
  @moduledoc """
  Channel record schema and helper functions.
  """
  use Memento.Table,
    attributes: [
      :yt_channel_id,
      :name,
      :twitter_link,
      :view_count,
      :subscriber_count,
      :video_count
    ],
    index: [:name],
    type: :set

  def build_record(channel) do
    %__MODULE__{
      yt_channel_id: channel["yt_channel_id"],
      name: channel["name"],
      twitter_link: channel["twitter_link"],
      view_count: channel["view_count"],
      subscriber_count: channel["subscriber_count"],
      video_count: channel["video_count"]
    }
  end
end