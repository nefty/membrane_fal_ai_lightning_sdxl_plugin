defmodule LiveViewWeb.PageController do
  use LiveViewWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
