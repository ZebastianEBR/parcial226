defmodule Parcial2.Tareas.Validacion do
  @moduledoc """
  Validación previa (recursiva) de la red de tareas.

  Por exigencia del enunciado, NINGUNA función de este módulo llama a
  `Enum` ni a `Stream`: todo se hace con recursión sobre listas y con
  operadores como `++`. Se verifica:

  - IDs duplicados, vacíos o con `|`;
  - duraciones positivas y plazos no negativos;
  - dependencias repetidas, desconocidas o a sí misma;
  - ciclos (cada ciclo se informa una sola vez, sin rotaciones).

  Recibe `registros`: lista de `{numero_de_linea, %Parcial2.Tarea{}}`.
  Retorna una lista de mensajes de error (vacía si todo está bien).
  """

  alias Parcial2.Tarea

  def validar(registros) do
    ids = ids_de(registros)
    grafo = construir_grafo(registros, ids, [])

    duplicados(registros, []) ++
      valores(registros) ++
      dependencias(registros, ids) ++
      mensajes_ciclos(ciclos(grafo))
  end

  # ---------- utilidades recursivas ----------

  defp miembro?(_x, []), do: false
  defp miembro?(x, [x | _]), do: true
  defp miembro?(x, [_ | resto]), do: miembro?(x, resto)

  defp ids_de([]), do: []
  defp ids_de([{_numero, %Tarea{id: id}} | resto]), do: [id | ids_de(resto)]

  defp unir([], _separador), do: ""
  defp unir([x], _separador), do: x
  defp unir([x | resto], separador), do: x <> separador <> unir(resto, separador)

  # ---------- IDs duplicados ----------

  defp duplicados([], _vistos), do: []

  defp duplicados([{numero, tarea} | resto], vistos) do
    case linea_de(vistos, tarea.id) do
      nil ->
        duplicados(resto, [{tarea.id, numero} | vistos])

      primera ->
        [
          "Línea #{numero}: el ID \"#{tarea.id}\" está duplicado (primera aparición en la línea #{primera})."
          | duplicados(resto, vistos)
        ]
    end
  end

  defp linea_de([], _id), do: nil
  defp linea_de([{id, linea} | _], id), do: linea
  defp linea_de([_ | resto], id), do: linea_de(resto, id)

  # ---------- IDs, duraciones y plazos ----------

  defp valores([]), do: []

  defp valores([{numero, tarea} | resto]) do
    errores_id(numero, tarea.id) ++ errores_numericos(numero, tarea) ++ valores(resto)
  end

  defp errores_id(numero, id) do
    cond do
      id == "" -> ["Línea #{numero}: el ID está vacío."]
      String.contains?(id, "|") -> ["Línea #{numero}: el ID \"#{id}\" contiene el carácter '|'."]
      true -> []
    end
  end

  defp errores_numericos(numero, tarea) do
    if(tarea.duracion <= 0,
      do: ["Línea #{numero}: la duración de \"#{tarea.id}\" debe ser un entero positivo (es #{tarea.duracion})."],
      else: []
    ) ++
      if(tarea.plazo < 0,
        do: ["Línea #{numero}: el plazo de \"#{tarea.id}\" debe ser un entero no negativo (es #{tarea.plazo})."],
        else: []
      )
  end

  # ---------- dependencias ----------

  defp dependencias([], _ids), do: []

  defp dependencias([{numero, tarea} | resto], ids) do
    revisar(tarea.dependencias, [], numero, tarea.id, ids) ++ dependencias(resto, ids)
  end

  defp revisar([], _vistas, _numero, _id, _ids), do: []

  defp revisar([dep | resto], vistas, numero, id, ids) do
    errores =
      cond do
        dep == id ->
          ["Línea #{numero}: la tarea \"#{id}\" depende de sí misma."]

        miembro?(dep, vistas) ->
          ["Línea #{numero}: la dependencia \"#{dep}\" está repetida en la tarea \"#{id}\"."]

        not miembro?(dep, ids) ->
          ["Línea #{numero}: la tarea \"#{id}\" depende de \"#{dep}\", que no existe."]

        true ->
          []
      end

    errores ++ revisar(resto, [dep | vistas], numero, id, ids)
  end

  # ---------- grafo limpio (sin duplicados, ni desconocidas, ni auto-dependencias) ----------

  defp construir_grafo([], _ids, _vistos), do: []

  defp construir_grafo([{_numero, tarea} | resto], ids, vistos) do
    if miembro?(tarea.id, vistos) do
      construir_grafo(resto, ids, vistos)
    else
      [
        {tarea.id, limpiar(tarea.dependencias, tarea.id, ids, [])}
        | construir_grafo(resto, ids, [tarea.id | vistos])
      ]
    end
  end

  defp limpiar([], _id, _ids, _vistas), do: []

  defp limpiar([dep | resto], id, ids, vistas) do
    if dep != id and miembro?(dep, ids) and not miembro?(dep, vistas) do
      [dep | limpiar(resto, id, ids, [dep | vistas])]
    else
      limpiar(resto, id, ids, vistas)
    end
  end

  # ---------- ciclos ----------

  @doc """
  Encuentra todos los ciclos elementales de un grafo `[{id, [dependencias]}]`.

  Cada ciclo se busca únicamente desde su primer nodo en la lista (los demás
  nodos del ciclo deben venir después), de modo que no aparecen rotaciones
  repetidas. Un ciclo `[A, C, B]` significa A depende de C, C de B y B de A.
  """
  def ciclos(grafo), do: iniciar(grafo, grafo)

  defp iniciar([], _grafo), do: []

  defp iniciar([{inicio, deps} | resto], grafo) do
    permitidos = [inicio | ids_grafo(resto)]
    explorar(inicio, deps, permitidos, grafo, [inicio]) ++ iniciar(resto, grafo)
  end

  defp explorar(_inicio, [], _permitidos, _grafo, _camino), do: []

  defp explorar(inicio, [vecino | otros], permitidos, grafo, camino) do
    encontrados =
      cond do
        vecino == inicio -> [:lists.reverse(camino)]
        not miembro?(vecino, permitidos) -> []
        miembro?(vecino, camino) -> []
        true -> explorar(inicio, deps_de(vecino, grafo), permitidos, grafo, [vecino | camino])
      end

    encontrados ++ explorar(inicio, otros, permitidos, grafo, camino)
  end

  defp ids_grafo([]), do: []
  defp ids_grafo([{id, _} | resto]), do: [id | ids_grafo(resto)]

  defp deps_de(_id, []), do: []
  defp deps_de(id, [{id, deps} | _]), do: deps
  defp deps_de(id, [_ | resto]), do: deps_de(id, resto)

  defp mensajes_ciclos([]), do: []

  defp mensajes_ciclos([ciclo | resto]) do
    cerrado = ciclo ++ [hd(ciclo)]

    [
      "Ciclo de dependencias: #{unir(cerrado, " -> ")} (cada tarea depende de la siguiente)."
      | mensajes_ciclos(resto)
    ]
  end
end
