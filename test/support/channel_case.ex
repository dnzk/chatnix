defmodule ChatnixWeb.ChannelCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Phoenix.ChannelTest
      import ChatnixWeb.ChannelCase

      @endpoint ChatnixWeb.Endpoint
    end
  end

  setup tags do
    Chatnix.DataCase.setup_sandbox(tags)
    :ok
  end
end
