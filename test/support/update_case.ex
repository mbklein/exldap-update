defmodule Exldap.UpdateCase do
  @moduledoc """
  Helpers for Exldap.Update tests
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      def load(conn, dn) do
        Exldap.search(conn,
          base: dn,
          scope: :eldap.baseObject(),
          filter: Exldap.equalityMatch("objectClass", "top")
        )
      end
    end
  end

  setup_all do
    with {:ok, connection} <- Exldap.connect() do
      :eldap.add(connection, 'OU=test,DC=example,DC=org', [
        {'objectClass', ['top', 'organizationalUnit']}
      ])
    end

    :ok
  end

  setup do
    on_exit(&empty_base/0)
  end

  def empty_base do
    with {:ok, connection} <- Exldap.connect(),
         base <- "ou=test,dc=example,dc=org" do
      {:ok, children} =
        Exldap.search(connection,
          base: base,
          scope: :eldap.wholeSubtree(),
          filter: Exldap.equalityMatch("objectClass", "top")
        )

      children
      |> Enum.each(fn leaf ->
        case leaf.object_name |> to_string() |> String.downcase() do
          ^base -> :noop
          dn -> :eldap.delete(connection, to_charlist(dn))
        end
      end)
    end
  end
end
