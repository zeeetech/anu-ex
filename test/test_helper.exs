alias Anu.Cloud.ClientMock

Application.put_env(:anu, :adapter, Anu.Adapters.Test)
Application.put_env(:anu, :access_token, "test_token")
Application.put_env(:anu, :phone_number_id, "test_phone_id")
Application.put_env(:anu, :verify_token, "test_verify_token")
Application.put_env(:anu, :app_secret, "test_app_secret")

Mox.defmock(ClientMock, for: Anu.Cloud.Client)
Application.put_env(:anu, :cloud_client, ClientMock)

ExUnit.start()
