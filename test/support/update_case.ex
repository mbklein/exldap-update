defmodule Exldap.UpdateCase do
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

  setup do
    on_exit(&empty_base/0)
  end

  def empty_base do
    with {:ok, connection} <- Exldap.connect(),
         base <- "DC=example,DC=org" do
      {:ok, children} =
        Exldap.search(connection,
          base: base,
          scope: :eldap.wholeSubtree(),
          filter:
            Exldap.with_and([
              Exldap.negate(Exldap.equalityMatch("distinguishedName", base)),
              Exldap.equalityMatch("objectClass", "top")
            ])
        )

      children
      |> Enum.each(fn leaf ->
        :eldap.delete(connection, leaf.object_name)
      end)
    end
  end
end
