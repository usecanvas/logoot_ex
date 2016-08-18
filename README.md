# Logoot

An Elixir implementation of the
[Logoot CRDT](https://hal.archives-ouvertes.fr/inria-00432368/document).

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
as:

  1. Add `logoot` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:logoot, "~> 0.1.0"}]
    end
    ```

  2. Ensure `logoot` is started before your application:

    ```elixir
    def application do
      [applications: [:logoot]]
    end
    ```
