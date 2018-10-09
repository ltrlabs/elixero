defmodule EliXero.Utils.Oauth do
  def oauth_consumer_key(client) do
    client.access_token["oauth_token"]
  end

  def oauth_consumer_secret(client) do
    client.consumer_secret
  end

  def application_type(client) do
    client.app_type
  end

  def private_key(client) do
    client.private_key_path
  end

  def create_auth_header(method, url, client, additional_params, token) do
    {base_string, oauth_params} = create_oauth_context(method, url, client, additional_params)

    signature = sign(client, base_string, token)

    "OAuth oauth_signature=\"" <> signature <> "\", " <> EliXero.Utils.Helpers.join_params_keyword(oauth_params, :auth_header)
  end

  def create_auth_header(method, url, client, additional_params) do
    {base_string, oauth_params} = create_oauth_context(method, url, client, additional_params)

    signature = sign(client, base_string)

    "OAuth oauth_signature=\"" <> signature <> "\", " <> EliXero.Utils.Helpers.join_params_keyword(oauth_params, :auth_header)
  end

  defp create_oauth_context(method, url, client, additional_params) do
    timestamp = :erlang.float_to_binary(Float.floor(:os.system_time(:milli_seconds) / 1000), [{:decimals, 0}])

    oauth_signing_params = [
        oauth_consumer_key: oauth_consumer_key(client),
        oauth_nonce: EliXero.Utils.Helpers.random_string(10),
        oauth_signature_method: signature_method(client),
        oauth_version: "1.0",
        oauth_timestamp: timestamp
      ]

    params = additional_params ++ oauth_signing_params

    uri_parts = String.split(url, "?")
    url = Enum.at(uri_parts, 0)

    params_with_extras =
      if (length(uri_parts) > 1) do
        query_params = Enum.at(uri_parts, 1) |> URI.decode_query |> Enum.map(fn({key, value}) -> {String.to_atom(key),  URI.encode_www_form(value) |> String.replace("+", "%20") } end)
        params ++ query_params
      else
        params
      end

    params_with_extras = Enum.sort(params_with_extras)

    base_string =
      method <> "&" <>
      URI.encode_www_form(url) <> "&" <>
      URI.encode_www_form(
        EliXero.Utils.Helpers.join_params_keyword(params_with_extras, :base_string)
      )

    {base_string, params}
  end

  def sign(client, base_string) do
    rsa_sha1_sign(client, base_string)
  end

  def sign(client ,base_string, token) do
    hmac_sha1_sign(client, base_string, token)
  end

  defp signature_method(client) do
    case(application_type(client)) do
      :private -> "RSA-SHA1"
      :public -> "HMAC-SHA1"
      :partner -> "RSA-SHA1"
    end
  end

  defp rsa_sha1_sign(client, base_string) do
    hashed = :crypto.hash(:sha, base_string)

    {:ok, body} = File.read private_key(client)

    [decoded_key] = :public_key.pem_decode(body)
    key = :public_key.pem_entry_decode(decoded_key)
    signed = :public_key.encrypt_private(hashed, key)
    URI.encode(Base.encode64(signed), &URI.char_unreserved?(&1))
  end

  defp hmac_sha1_sign(client, base_string, token) do
    key =
      case(token) do
        nil -> oauth_consumer_secret(client) <> "&"
        _ -> oauth_consumer_secret(client) <> "&" <> token["oauth_token_secret"]
      end
    signed = :crypto.hmac(:sha, key, base_string)
    URI.encode(Base.encode64(signed), &URI.char_unreserved?(&1))
  end

end
