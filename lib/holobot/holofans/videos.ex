defmodule Holobot.Holofans.Videos do
  @moduledoc """
  Holofans API caching server.
  """
  use GenServer

  require Logger
  require Memento

  alias Holobot.Holofans.Video

  @cache_limit 1000
  @cache_update_interval 300_000

  def start_link(init_args \\ []) do
    Logger.info("Started cache server")
    setup_tables()
    GenServer.start_link(__MODULE__, [init_args], name: __MODULE__)
  end

  @impl true
  def init(_args) do
    # Start the update loop
    update()
    {:ok, :initial_state}
  end

  @impl true
  def handle_cast(:update, _state) do
    Logger.info("Handling update")
    # Do fetching from API and writing to cache
    :ok = cache_videos!("upcoming")

    Process.sleep(@cache_update_interval)
    update()

    {:noreply, :ok}
  end

  # Client

  @doc """
  Update the cache state.
  """
  @spec update(atom | pid | {atom, any} | {:via, atom, any}) :: :ok
  def update(pid \\ __MODULE__) do
    GenServer.cast(pid, :update)
  end

  @doc """
  Get a video by its Youtube video ID
  """
  @spec get_video(binary()) :: %Video{} | nil
  def get_video(yt_vid_key) do
    Memento.transaction!(fn ->
      Memento.Query.read(Video, yt_vid_key)
    end)
  end

  # Helpers

  defp setup_tables() do
    # Create the ETS/Mnesia tables
    Logger.info("Setting up Mnesia tables")
    Memento.Table.create!(Video)
  end

  defp cache_videos!(status) do
    # video request chunk size, <= 50
    step = 50

    filters = %{
      limit: step,
      status: status
    }

    try do
      %{"total" => total} = fetch_videos!(filters)

      # Set number of total results to fetch
      items_to_fetch =
        cond do
          total >= @cache_limit -> @cache_limit
          total < @cache_limit -> total
        end

      if items_to_fetch > 0 do
        0..items_to_fetch
        |> Stream.filter(&(rem(&1, step) == 0))
        |> Enum.each(fn offset ->
          Logger.debug("Current offset: #{offset}")

          videos_chunk =
            filters
            |> Map.merge(%{offset: offset})
            |> fetch_videos!()
            |> Map.get("videos")
            |> Enum.map(&Video.build_record/1)

          Memento.transaction!(fn ->
            for video <- videos_chunk, do: Memento.Query.write(video)
          end)
        end)

        Logger.info(
          "Cached total of #{items_to_fetch} videos of status: #{String.upcase(status)}"
        )
      else
        Logger.info("Nothing to cache, skipping.")
        :ok
      end
    rescue
      RuntimeError -> "Error when caching videos of status: #{status}!"
    end
  end

  defp fetch_videos!(params) do
    holofans_api_base = Application.fetch_env!(:holobot, :holofans_api)
    path = "/v1/videos"

    url =
      holofans_api_base
      |> URI.parse()
      |> URI.merge(path)
      |> Map.put(:query, URI.encode_query(params))
      |> URI.to_string()

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, decoded} = Jason.decode(body)
        decoded

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        Logger.warning("Resource not found")

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error(reason)
    end
  end
end
