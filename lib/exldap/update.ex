defmodule Exldap.Update do
  @moduledoc """
  A module for adding / updating information in LDAP from Elixir via Exldap
  """

  @type distinguished_name :: String.t()
  @type modify_op :: term()
  @type return_value :: :ok | {:ok, {:referral, [String.t()]}} | {:error, term()}

  @doc """
  Add an entry. The entry must not exist. Attributes can be supplied
  either as a map or a keyword list, with either atoms or strings as keys.

  ## Examples:

      iex> Exldap.Update.add(
      ...>   connection,
      ...>   "CN=someUser,OU=Accounts,DC=example,DC=com",
      ...>   %{objectClass: ["person", "top"], sn: "User", cn: "someUser"}
      ...> )
      :ok


      iex> Exldap.Update.add(
      ...>   connection,
      ...>   "CN=someUser,OU=Accounts,DC=example,DC=com",
      ...>   [{"objectClass", "top"}, objectClass: "person", sn: "User", cn: "someUser"]
      ...> )
      :ok
  """
  @spec add(pid(), distinguished_name(), map() | list(keyword())) :: return_value()
  def add(connection, dn, attrs) do
    :eldap.add(connection, force_charlist(dn), convert_attributes(attrs))
  end

  @doc """
  Delete an entry.

  ## Example:

      iex> Exldap.Update.delete(connection, "CN=someUser,OU=Accounts,DC=example,DC=com")
      :ok
      iex> Exldap.Update.delete(connection, "CN=someUser,OU=Accounts,DC=example,DC=com")
      {:error, :noSuchObject}
  """
  @spec delete(pid(), distinguished_name()) :: return_value()
  def delete(connection, dn) do
    :eldap.delete(connection, force_charlist(dn))
  end

  @spec mod_add(term(), term() | list(term())) :: modify_op()
  def mod_add(type, values) do
    with {k, v} <- convert_attribute_value({type, values}) do
      :eldap.mod_add(k, v)
    end
  end

  @spec mod_delete(term(), term() | list(term())) :: modify_op()
  def mod_delete(type, values) do
    with {k, v} <- convert_attribute_value({type, values}) do
      :eldap.mod_delete(k, v)
    end
  end

  @spec mod_replace(term(), term() | list(term())) :: modify_op()
  def mod_replace(type, values) do
    with {k, v} <- convert_attribute_value({type, values}) do
      :eldap.mod_replace(k, v)
    end
  end

  @doc """
  Modify an entry.

  ## Examples:

      iex> Exldap.Update.modify(
      ...>   connection,
      ...>   "CN=someUser,OU=Accounts,DC=example,DC=com",
      ...>   Exldap.Update.mod_add("displayName", "Some User")
      ...> )
      :ok

      iex> Exldap.Update.modify(
      ...>   connection,
      ...>   "CN=someUser,OU=Accounts,DC=example,DC=com",
      ...>   [
      ...>     Exldap.Update.mod_add("mail", ["someuser@example.com", "some.user@example.com"]),
      ...>     Exldap.Update.mod_delete("displayName", "Some User")
      ...>   ]
      ...> )
      :ok
  """
  @spec modify(pid(), distinguished_name(), modify_op() | list(modify_op())) :: return_value()
  def modify(connection, dn, ops) when is_list(ops) do
    :eldap.modify(connection, force_charlist(dn), ops)
  end

  def modify(connection, dn, op), do: modify(connection, dn, [op])

  defp convert_attribute_value({key, val}) when is_list(val) do
    {
      key |> force_charlist(),
      val |> Enum.map(&force_charlist/1)
    }
  end

  defp convert_attribute_value({key, val}), do: convert_attribute_value({key, [val]})

  defp convert_attributes(attrs) do
    attrs
    |> flat_attribute_list()
    |> Enum.map(&convert_attribute_value/1)
  end

  defp flat_attribute_list(attrs) do
    attrs
    |> Enum.reduce([], fn {key, val}, acc ->
      key =
        cond do
          is_atom(key) -> key
          is_binary(key) -> String.to_atom(key)
          true -> String.to_atom(to_string(key))
        end

      val = if is_list(val), do: val, else: [val]
      acc |> Keyword.update(key, val, fn v -> v ++ val end)
    end)
  end

  defp force_charlist(v), do: v |> to_string() |> to_charlist()
end
