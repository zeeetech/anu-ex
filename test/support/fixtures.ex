defmodule Anu.Fixtures do
  @moduledoc false

  def text_message_payload do
    %{
      "entry" => [
        %{
          "id" => "WHATSAPP_BUSINESS_ACCOUNT_ID",
          "changes" => [
            %{
              "value" => %{
                "messaging_product" => "whatsapp",
                "metadata" => %{
                  "display_phone_number" => "5511999999999",
                  "phone_number_id" => "PHONE_NUMBER_ID"
                },
                "messages" => [
                  %{
                    "id" => "wamid.HBgNNTUxMTk5OTk5OTk5OQ==",
                    "from" => "5511888888888",
                    "timestamp" => "1234567890",
                    "type" => "text",
                    "text" => %{"body" => "Hello!"}
                  }
                ]
              },
              "field" => "messages"
            }
          ]
        }
      ]
    }
  end

  def status_update_payload(status \\ "delivered") do
    %{
      "entry" => [
        %{
          "id" => "WHATSAPP_BUSINESS_ACCOUNT_ID",
          "changes" => [
            %{
              "value" => %{
                "messaging_product" => "whatsapp",
                "statuses" => [
                  %{
                    "id" => "wamid.HBgNNTUxMTk5OTk5OTk5OQ==",
                    "status" => status,
                    "timestamp" => "1234567890",
                    "recipient_id" => "5511999999999"
                  }
                ]
              },
              "field" => "messages"
            }
          ]
        }
      ]
    }
  end

  def button_reply_payload do
    %{
      "entry" => [
        %{
          "id" => "WHATSAPP_BUSINESS_ACCOUNT_ID",
          "changes" => [
            %{
              "value" => %{
                "messaging_product" => "whatsapp",
                "messages" => [
                  %{
                    "id" => "wamid.button123",
                    "from" => "5511888888888",
                    "timestamp" => "1234567890",
                    "type" => "interactive",
                    "interactive" => %{
                      "type" => "button_reply",
                      "button_reply" => %{"id" => "btn_yes", "title" => "Yes"}
                    }
                  }
                ]
              },
              "field" => "messages"
            }
          ]
        }
      ]
    }
  end

  def image_message_payload do
    %{
      "entry" => [
        %{
          "id" => "WHATSAPP_BUSINESS_ACCOUNT_ID",
          "changes" => [
            %{
              "value" => %{
                "messaging_product" => "whatsapp",
                "messages" => [
                  %{
                    "id" => "wamid.img123",
                    "from" => "5511888888888",
                    "timestamp" => "1234567890",
                    "type" => "image",
                    "image" => %{
                      "mime_type" => "image/jpeg",
                      "sha256" => "abc123",
                      "id" => "MEDIA_ID"
                    }
                  }
                ]
              },
              "field" => "messages"
            }
          ]
        }
      ]
    }
  end
end
