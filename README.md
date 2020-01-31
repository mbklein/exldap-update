# Exldap.Update

A module for updating LDAP from Elixir via [Exldap](https://hexdocs.pm/exldap)

[![CircleCI](https://circleci.com/gh/mbklein/exldap-update.svg?style=svg)](https://circleci.com/gh/mbklein/exldap-update)
[![Coverage Status](https://coveralls.io/repos/github/mbklein/exldap-update/badge.svg?branch=master)](https://coveralls.io/github/mbklein/exldap-update?branch=master)

## Installation

The package can be installed by adding `exldap_update` to your list of
dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:exldap_update, "~> 0.1.0"}
  ]
end
```

See the [Exldap installation instructions](https://hexdocs.pm/exldap/readme.html) to
learn how to properly configure your application to use `Exldap` and `Exldap.Update`.

## Usage

`Exldap.Update` is essentially a common sense wrapper around the `add`, `delete`,
and `modify` functions from Erlang's [`eldap`](http://erlang.org/doc/man/eldap.html)
module with some syntactic sugar sprinkled on top:

* Distinguished names, attribute names, and values can be provided as binary strings
  instead of charlists
* Attributes can be passed to `add` either as a map or a keyword list with strings
  or atoms as keys

```
  {:ok, connection} = Exldap.connect()
  dn = "CN=ghopper,OU=people,DC=example,DC=org"
  attrs = %{objectClass: ["top", "person"], sn: "Hopper", description: "Admiral Grace Hopper"}
  
  case Exldap.Update.add(connection, dn, attrs) do
    :ok -> IO.puts "Added new entry"
    {:error, :entryAlreadyExists} -> IO.puts "Entry already exists"
    {:error, other} -> IO.puts "Error: #{other}"
  end

  Exldap.Udpate.modify(connection dn, Exldap.Update.mod_add("displayName", "Admiral Grace Hopper"))
  Exldap.Udpate.modify(connection dn, Exldap.Update.mod_replace("description", "Hopper, Grace (1906-1992)"))
  
  Exldap.Update.delete(connection, dn)
```
