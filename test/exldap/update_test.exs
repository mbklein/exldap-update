defmodule Exldap.UpdateTest do
  use Exldap.UpdateCase
  alias Exldap.Update
  import Assertions

  setup do
    {:ok, connection} = Exldap.connect()
    {:ok, conn: connection}
  end

  describe "Add an entry" do
    setup %{conn: conn, attrs: attrs} do
      result = Update.add(conn, "OU=NewOrgUnit,DC=example,DC=org", attrs)
      {:ok, [entry]} = conn |> load("OU=NewOrgUnit,DC=example,DC=org")
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
    with dn <- "CN=dupe,DC=example,DC=org",
         attrs <- %{objectClass: ["top", "person"], sn: "Dupe"} do
      assert Update.add(conn, dn, attrs) == :ok
      assert Update.add(conn, dn, attrs) == {:error, :entryAlreadyExists}
    end
  end

  test "delete an entry", %{conn: conn} do
    with dn <- "CN=disposable,DC=example,DC=org",
         attrs <- %{objectClass: ["top", "person"], sn: "Disposable"} do
      assert Update.add(conn, dn, attrs) == :ok
      assert Update.delete(conn, dn) == :ok
      assert conn |> load(dn) == {:error, :noSuchObject}
    end
  end

  test "delete an entry that doesn't exist", %{conn: conn} do
    assert Update.delete(conn, "CN=nothing,DC=example,DC=org") == {:error, :noSuchObject}
  end

  describe "modify an object" do
    setup %{conn: conn} do
      dn = "CN=changeme,DC=example,DC=org"

      :ok =
        Update.add(conn, dn, %{
          objectClass: ["top", "person"],
          description: "Object for Change",
          sn: "ChangeMe"
        })

      {:ok, %{conn: conn, dn: dn}}
    end

    test "add a value", %{conn: conn, dn: dn} do
      mod_ops = Update.mod_add("description", ["Change for Object"])
      assert :ok == Update.modify(conn, dn, mod_ops)
      {:ok, [entry]} = conn |> load(dn)

      Exldap.get_attribute!(entry, "description")
      |> assert_lists_equal(["Object for Change", "Change for Object"])
    end

    test "delete a value", %{conn: conn, dn: dn} do
      mod_ops = Update.mod_add("description", ["Change for Object"])
      assert :ok == Update.modify(conn, dn, mod_ops)

      mod_ops = Update.mod_delete("description", "Object for Change")
      assert :ok == Update.modify(conn, dn, mod_ops)
      {:ok, [entry]} = conn |> load(dn)
      assert Exldap.get_attribute!(entry, "description") == "Change for Object"
    end

    test "delete the only value", %{conn: conn, dn: dn} do
      mod_ops = Update.mod_delete("description", "Object for Change")
      assert :ok == Update.modify(conn, dn, mod_ops)
      {:ok, [entry]} = conn |> load(dn)
      assert Exldap.get_attribute!(entry, "description") |> is_nil()
    end

    test "replace a value", %{conn: conn, dn: dn} do
      mod_ops = Update.mod_replace("description", ["Change for Object", "Not Object for Change"])
      assert :ok == Update.modify(conn, dn, mod_ops)
      {:ok, [entry]} = conn |> load(dn)

      Exldap.get_attribute!(entry, "description")
      |> assert_lists_equal(["Change for Object", "Not Object for Change"])
    end

    test "multiple changes", %{conn: conn, dn: dn} do
      mod_ops = [
        Update.mod_add("description", ["Change for Object"]),
        Update.mod_replace("sn", "Changed")
      ]

      assert :ok == Update.modify(conn, dn, mod_ops)
      {:ok, [entry]} = conn |> load(dn)

      Exldap.get_attribute!(entry, "description")
      |> assert_lists_equal(["Change for Object", "Object for Change"])

      assert Exldap.get_attribute!(entry, "sn") == "Changed"
    end
  end
end
