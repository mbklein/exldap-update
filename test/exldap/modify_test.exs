defmodule Exldap.ModifyTest do
  use Exldap.UpdateCase
  alias Exldap.Update
  import Assertions

  defp modify_setup(%{conn: conn, mod_ops: mod_ops}) do
    dn = "CN=changeme,OU=test,DC=example,DC=org"

    :ok =
      Update.add(conn, dn, %{
        objectClass: ["top", "person"],
        description: ["Object for Change", "Second Value"],
        sn: "ChangeMe"
      })

    Update.modify(conn, dn, mod_ops)
    {:ok, [entry]} = conn |> load(dn)
    {:ok, %{dn: dn, entry: entry}}
  end

  describe "mod_add, mod_delete, mod_replace" do
    setup [:modify_setup]

    @tag mod_ops: Update.mod_add("description", ["Change for Object"])
    test "add a value", %{entry: entry} do
      Exldap.get_attribute!(entry, "description")
      |> assert_lists_equal(["Object for Change", "Second Value", "Change for Object"])
    end

    @tag mod_ops: Update.mod_delete("description", "Second Value")
    test "delete a value", %{entry: entry} do
      assert Exldap.get_attribute!(entry, "description") == "Object for Change"
    end

    @tag mod_ops: Update.mod_delete("description", ["Object for Change", "Second Value"])
    test "delete all values", %{entry: entry} do
      assert Exldap.get_attribute!(entry, "description") |> is_nil()
    end

    @tag mod_ops:
           Update.mod_replace("description", ["Change for Object", "Not Object for Change"])
    test "replace a value", %{entry: entry} do
      Exldap.get_attribute!(entry, "description")
      |> assert_lists_equal(["Change for Object", "Not Object for Change"])
    end

    @tag mod_ops: [
           Update.mod_add("description", ["Change for Object"]),
           Update.mod_replace("sn", "Changed")
         ]
    test "multiple changes", %{entry: entry} do
      Exldap.get_attribute!(entry, "description")
      |> assert_lists_equal(["Change for Object", "Second Value", "Object for Change"])

      assert Exldap.get_attribute!(entry, "sn") == "Changed"
    end
  end

  describe "{:add}, {:delete}, {:replace}" do
    setup [:modify_setup]

    @tag mod_ops: {:add, :description, ["Change for Object"]}
    test "add a value", %{entry: entry} do
      Exldap.get_attribute!(entry, "description")
      |> assert_lists_equal(["Object for Change", "Second Value", "Change for Object"])
    end

    @tag mod_ops: {:delete, :description, "Second Value"}
    test "delete a value", %{entry: entry} do
      assert Exldap.get_attribute!(entry, "description") == "Object for Change"
    end

    @tag mod_ops: {:delete, :description, ["Object for Change", "Second Value"]}
    test "delete all values", %{entry: entry} do
      assert Exldap.get_attribute!(entry, "description") |> is_nil()
    end

    @tag mod_ops: {:replace, :description, ["Change for Object", "Not Object for Change"]}
    test "replace a value", %{entry: entry} do
      Exldap.get_attribute!(entry, "description")
      |> assert_lists_equal(["Change for Object", "Not Object for Change"])
    end

    @tag mod_ops: [
           {:add, :description, ["Change for Object"]},
           {:replace, :sn, "Changed"}
         ]
    test "multiple changes", %{entry: entry} do
      Exldap.get_attribute!(entry, "description")
      |> assert_lists_equal(["Change for Object", "Second Value", "Object for Change"])

      assert Exldap.get_attribute!(entry, "sn") == "Changed"
    end
  end
end
