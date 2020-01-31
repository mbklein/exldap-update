use Mix.Config

config :exldap, :settings,
  server: "localhost",
  base: "DC=example,DC=org",
  port: 389,
  user_dn: "cn=admin,dc=example,dc=org",
  password: "admin"
