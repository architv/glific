defmodule Glific.Providers.Gupshup.Message do
  @moduledoc """
  Messgae API layer between application and Gupshup
  """

  @channel "whatsapp"
  @behaviour Glific.Providers.MessageBehaviour

  alias Glific.{
    Communications,
    Messages.Message,
    Partners
  }

  @doc false
  @impl Glific.Providers.MessageBehaviour
  @spec send_text(Message.t(), map()) ::
          {:ok, Oban.Job.t()} | {:error, Ecto.Changeset.t()} | {:error, String.t()}
  def send_text(message, attrs \\ %{}) do
    %{type: :text, text: message.body, isHSM: message.is_hsm}
    |> check_size()
    |> send_message(message, attrs)
  end

  @doc false
  @impl Glific.Providers.MessageBehaviour
  @spec send_image(Message.t(), map()) ::
          {:ok, Oban.Job.t()} | {:error, Ecto.Changeset.t()} | {:error, String.t()}
  def send_image(message, attrs \\ %{}) do
    message_media = message.media

    %{
      type: :image,
      originalUrl: message_media.source_url,
      previewUrl: message_media.url,
      caption: caption(message_media.caption)
    }
    |> check_size()
    |> send_message(message, attrs)
  end

  @doc false

  @impl Glific.Providers.MessageBehaviour
  @spec send_audio(Message.t(), map()) :: {:ok, Oban.Job.t()} | {:error, Ecto.Changeset.t()}
  def send_audio(message, attrs \\ %{}) do
    message_media = message.media

    %{
      type: :audio,
      url: message_media.source_url
    }
    |> send_message(message, attrs)
  end

  @doc false
  @impl Glific.Providers.MessageBehaviour
  @spec send_video(Message.t(), map()) ::
          {:ok, Oban.Job.t()} | {:error, Ecto.Changeset.t()} | {:error, String.t()}
  def send_video(message, attrs \\ %{}) do
    message_media = message.media

    %{
      type: :video,
      url: message_media.source_url,
      caption: caption(message_media.caption)
    }
    |> check_size()
    |> send_message(message, attrs)
  end

  @doc false
  @impl Glific.Providers.MessageBehaviour
  @spec send_document(Message.t(), map()) ::
          {:ok, Oban.Job.t()} | {:error, Ecto.Changeset.t()}
  def send_document(message, attrs \\ %{}) do
    message_media = message.media

    %{
      type: :file,
      url: message_media.source_url,
      filename: message_media.caption
    }
    |> send_message(message, attrs)
  end

  @doc false
  @impl Glific.Providers.MessageBehaviour
  @spec send_sticker(Message.t(), map()) :: {:ok, Oban.Job.t()} | {:error, Ecto.Changeset.t()}
  def send_sticker(message, attrs \\ %{}) do
    message_media = message.media

    %{
      type: :sticker,
      url: message_media.url
    }
    |> send_message(message, attrs)
  end

  @doc false
  @spec caption(nil | String.t()) :: String.t()
  defp caption(nil), do: ""
  defp caption(caption), do: caption

  @spec context_id(map()) :: String.t() | nil
  defp context_id(payload),
    do: get_in(payload, ["context", "gsId"]) || get_in(payload, ["context", "id"])

  @doc false
  @impl Glific.Providers.MessageBehaviour
  @spec receive_text(payload :: map()) :: map()
  def receive_text(params) do
    payload = params["payload"]
    message_payload = payload["payload"]

    %{
      bsp_message_id: payload["id"],
      context_id: context_id(payload),
      body: message_payload["text"],
      sender: %{
        phone: payload["sender"]["phone"],
        name: payload["sender"]["name"]
      }
    }
  end

  @doc false
  @impl Glific.Providers.MessageBehaviour
  @spec receive_media(map()) :: map()
  def receive_media(params) do
    payload = params["payload"]
    message_payload = payload["payload"]

    %{
      bsp_message_id: payload["id"],
      context_id: context_id(payload),
      caption: message_payload["caption"],
      url: message_payload["url"],
      source_url: message_payload["url"],
      sender: %{
        phone: payload["sender"]["phone"],
        name: payload["sender"]["name"]
      }
    }
  end

  @doc false
  @impl Glific.Providers.MessageBehaviour
  @spec receive_location(map()) :: map()
  def receive_location(params) do
    payload = params["payload"]
    message_payload = payload["payload"]

    %{
      bsp_message_id: payload["id"],
      context_id: context_id(payload),
      longitude: message_payload["longitude"],
      latitude: message_payload["latitude"],
      sender: %{
        phone: payload["sender"]["phone"],
        name: payload["sender"]["name"]
      }
    }
  end

  @doc false
  @spec format_sender(Message.t()) :: map()
  defp format_sender(message) do
    organization = Partners.organization(message.organization_id)

    %{
      "source" => message.sender.phone,
      "src.name" => organization.services["bsp"].secrets["app_name"]
    }
  end

  @max_size 4096
  @doc false
  @spec check_size(map()) :: map()
  defp check_size(%{text: text} = attrs) do
    if String.length(text) < @max_size,
      do: attrs,
      else: attrs |> Map.merge(%{error: "Message size greater than #{@max_size} characters"})
  end

  defp check_size(%{caption: caption} = attrs) do
    if String.length(caption) < @max_size,
      do: attrs,
      else: attrs |> Map.merge(%{error: "Message size greater than #{@max_size} characters"})
  end

  @doc false
  @spec send_message(map(), Message.t(), map()) ::
          {:ok, Oban.Job.t()} | {:error, Ecto.Changeset.t()} | {:error, String.t()}
  defp send_message(%{error: error} = _payload, _message, _attrs), do: {:error, error}

  defp send_message(payload, message, attrs) do
    request_body =
      %{"channel" => @channel}
      |> Map.merge(format_sender(message))
      |> Map.put(:destination, message.receiver.phone)
      |> Map.put("message", Jason.encode!(payload))

    ## gupshup does not allow null in the caption.
    attrs =
      if Map.has_key?(attrs, :caption) and is_nil(attrs[:caption]),
        do: Map.put(attrs, :caption, ""),
        else: attrs

    create_oban_job(message, request_body, attrs)
  end

  @doc false
  @spec to_minimal_map(map()) :: map()
  defp to_minimal_map(attrs) do
    Map.take(attrs, [:params, :template_id, :template_uuid, :is_hsm, :template_type])
  end

  @spec create_oban_job(Message.t(), map(), map()) ::
          {:ok, Oban.Job.t()} | {:error, Ecto.Changeset.t()}
  defp create_oban_job(message, request_body, attrs) do
    attrs = to_minimal_map(attrs)
    worker_module = Communications.provider_worker(message.organization_id)
    worker_args = %{message: Message.to_minimal_map(message), payload: request_body, attrs: attrs}

    apply(worker_module, :new, [worker_args, [scheduled_at: message.send_at]])
    |> Oban.insert()
  end
end
