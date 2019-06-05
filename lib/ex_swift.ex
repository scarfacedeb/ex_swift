defmodule ExSwift do
  alias ExSwift.{Request, Config}

  @doc "List containers in an account"
  def list_containers(params \\ %{})
  def list_containers(params), do: list_containers(Config.new(), params)

  def list_containers(%Config{} = config, params) do
    %Request{
      method: :get,
      path: "/",
      params: params
    }
    |> Request.run(config)
  end

  @doc "Create a new container in an account"
  def put_container(container_id) do
    %Request{
      method: :put,
      path: "/#{container_id}"
    }
    |> Request.run(Config.new())
  end

  @doc "Delete a container"
  def delete_container(container_id), do: delete_container(Config.new(), container_id)

  def delete_container(config, container_id) do
    %Request{
      method: :delete,
      path: "/#{container_id}"
    }
    |> Request.run(config)
  end

  @doc """
  List objects in a container.

  Max number of returned objects: 10000.

  Use stream_objects! for bigger containers.
  """
  def list_objects(container_id, params \\ %{})
  def list_objects(container_id, params), do: list_objects(Config.new(), container_id, params)

  def list_objects(%Config{} = config, container_id, params) do
    %Request{
      method: :get,
      path: "/#{container_id}",
      params: params
    }
    |> Request.run(config)
  end

  @doc "Stream objects in a container"
  def stream_objects!(container_id, opts \\ %{})
  def stream_objects!(container_id, opts), do: stream_objects!(Config.new(), container_id, opts)

  @default_page_limit 500

  def stream_objects!(%Config{} = config, container_id, opts) do
    opts = Enum.into(opts, %{})

    Stream.resource(
      fn -> Map.merge(%{limit: @default_page_limit, marker: nil}, opts) end,
      fn
        :last_page ->
          {:halt, nil}

        %{limit: limit} = params ->
          case list_objects(config, container_id, params) do
            {:ok, %{body: objects}} when length(objects) < limit ->
              {objects, :last_page}

            {:ok, %{body: objects}} when is_list(objects) ->
              last_object = objects |> List.last()
              {objects, %{params | marker: last_object["name"]}}

            {:error, error} ->
              error |> inspect() |> raise()
          end
      end,
      fn _ -> nil end
    )
  end

  @doc "Get a single object from a container"
  def get_object(container_id, object_id), do: get_object(Config.new(), container_id, object_id)

  def get_object(config, container_id, object_id) do
    %Request{
      method: :get,
      path: "/#{container_id}/#{object_id}"
    }
    |> Request.run(config)
  end

  @doc "Get an object's metadata"
  def head_object(container_id, object_id), do: head_object(Config.new(), container_id, object_id)

  def head_object(config, container_id, object_id) do
    %Request{
      method: :head,
      path: "/#{container_id}/#{object_id}"
    }
    |> Request.run(config)
  end

  @doc "Put an object into a container"
  def put_object(container_id, object_id, body),
    do: put_object(Config.new(), container_id, object_id, body)

  def put_object(config, container_id, object_id, body) do
    %Request{
      method: :put,
      path: "/#{container_id}/#{object_id}",
      body: body
    }
    |> Request.run(config)
  end

  @doc "Delete an object from a container"
  def delete_object(container_id, object_id),
    do: delete_object(Config.new(), container_id, object_id)

  def delete_object(config, container_id, object_id) do
    %Request{
      method: :delete,
      path: "/#{container_id}/#{object_id}"
    }
    |> Request.run(config)
  end

  @doc "Copy an object into another destination"
  def copy_object(container_id, object_id, destination),
    do: copy_object(Config.new(), container_id, object_id, destination)

  def copy_object(config, container_id, object_id, destination) do
    %Request{
      method: "COPY",
      path: "/#{container_id}/#{object_id}",
      headers: [{"destination", destination}]
    }
    |> Request.run(config)
  end
end
