defmodule GlificWeb.Resolvers.ConsultingHours do
  @moduledoc """
  Consulting Hours Resolver which sits between the GraphQL schema and Glific Consulting Hour Context API. This layer basically stiches together
  one or more calls to resolve the incoming queries.
  """

  alias Glific.{Saas.ConsultingHour, Repo}

  @doc """
  Get consulting hour
  """
  @spec get_consulting_hours(Absinthe.Resolution.t(), %{input: map()}, %{context: map()}) ::
          {:ok, any} | {:error, any}
  def get_consulting_hours(_, %{input: params}, _) do
    with consulting_hour <- ConsultingHour.get_consulting_hour(params) do
      {:ok, %{consulting_hour: consulting_hour}}
    end
  end

  @doc """
  Create consulting hour
  """
  @spec create_consulting_hour(Absinthe.Resolution.t(), %{input: map()}, %{context: map()}) ::
          {:ok, any} | {:error, any}
  def create_consulting_hour(_, %{input: params}, _) do
    with {:ok, consulting_hour} <- ConsultingHour.create_consulting_hour(params) do
      {:ok, %{consulting_hour: consulting_hour}}
    end
  end
end
