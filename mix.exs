defmodule Exldap.Update.MixProject do
  use Mix.Project

  @version "0.1.0"
  @url "https://github.com/mbklein/eldap-update"

  def project do
    [
      app: :exldap_update,
      name: "Exldap Update",
      description: "LDAP updating module for use with Exldap",
      version: @version,
      package: package(),
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.circle": :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:assertions, "~> 0.15.0", only: :test},
      {:excoveralls, "~> 0.10", only: :test},
      {:ex_doc, "~> 0.19", only: [:dev, :docs]},
      {:exldap, "~> 0.6.3"}
    ]
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      maintainers: ["Michael B. Klein"],
      links: %{GitHub: @url}
    ]
  end
end
