defmodule Exldap.UpdateTest do
  use Exldap.UpdateCase
  alias Exldap.Update
  import Assertions

  describe "Add an entry" do
    setup %{conn: conn, attrs: attrs} do
      result = Update.add(conn, "OU=NewOrgUnit,OU=test,DC=example,DC=org", attrs)
      {:ok, [entry]} = conn |> load("OU=NewOrgUnit,OU=test,DC=example,DC=org")
      {:ok, %{result: result, entry: entry}}
    end

    @tag attrs: %{
           "objectClass" => ["top", "organizationalUnit"],
           description: "New Organizational Unit"
         }
    test "using map attributes", %{result: result, entry: entry} do
      assert result == :ok
      assert Exldap.get_attribute!(entry, "description") == "New Organizational Unit"

      assert_lists_equal(Exldap.get_attribute!(entry, "objectClass"), [
        "top",
        "organizationalUnit"
      ])
    end

    @tag attrs: [
           {'description', "New Organizational Unit"},
           objectClass: "top",
           objectClass: "organizationalUnit"
         ]
    test "using keyword attributes", %{result: result, entry: entry} do
      assert result == :ok
      assert Exldap.get_attribute!(entry, "description") == "New Organizational Unit"

      Exldap.get_attribute!(entry, "objectClass")
      |> assert_lists_equal(["top", "organizationalUnit"])
    end
  end

  test "add an entry that already exists", %{conn: conn} do
    with dn <- "CN=dupe,OU=test,DC=example,DC=org",
         attrs <- %{objectClass: ["top", "person"], sn: "Dupe"} do
      assert Update.add(conn, dn, attrs) == :ok
      assert Update.add(conn, dn, attrs) == {:error, :entryAlreadyExists}
    end
  end

  test "delete an entry", %{conn: conn} do
    with dn <- "CN=disposable,OU=test,DC=example,DC=org",
         attrs <- %{objectClass: ["top", "person"], sn: "Disposable"} do
      assert Update.add(conn, dn, attrs) == :ok
      assert Update.delete(conn, dn) == :ok
      assert conn |> load(dn) == {:error, :noSuchObject}
    end
  end

  test "delete an entry that doesn't exist", %{conn: conn} do
    assert Update.delete(conn, "CN=nothing,OU=test,DC=example,DC=org") == {:error, :noSuchObject}
  end
end
