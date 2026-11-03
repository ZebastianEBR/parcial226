defmodule Parcial2.Tareas do
  @moduledoc """
  PROBLEMA 2: planificación de tareas con dependencias.

  Se ejecuta con `elixir problema2_tareas/principal.exs`.

  Flujo: leer `tareas.csv` en flujo -> validar recursivamente -> si la red es
  válida, enumerar recursivamente todos los órdenes posibles escribiendo cada
  plan a medida que se produce -> resumen y diagrama de Gantt (SVG).
  """

  alias Parcial2.{Archivos, Plan, Tarea}
  alias Parcial2.Tareas.{Svg, Validacion}

  def ejecutar(dir_datos, dir_salida) do
    Util2.mostrar("\n--- Problema 2: planificación de tareas ---", :mensaje)
    ruta = Path.join(dir_datos, "tareas.csv")

    if Archivos.existe?(ruta, "de tareas") do
      {registros, errores_formato} = leer(ruta)
      errores = errores_formato ++ Validacion.validar(registros)

      escribir_validacion(Path.join(dir_salida, "validacion_tareas.txt"), errores)

      case errores do
        [] ->
          planificar(registros, dir_salida)

        _ ->
          Util2.mostrar(
            "La red de tareas es inválida (#{length(errores)} problema(s)). " <>
              "Vea validacion_tareas.txt. No se enumeran planes.",
            :error
          )

          Svg.escribir_leyenda(
            Path.join(dir_salida, "mejor_plan.svg"),
            "Red de tareas inválida: no se generaron planes"
          )
      end
    end

    :ok
  end

  # ------------------------------------------------------------------
  # Lectura en flujo y conversión perezosa a structs
  # ------------------------------------------------------------------

  @doc false
  def leer(ruta) do
    resultados =
      ruta
      |> Archivos.lineas_utiles()
      |> Stream.map(&parsear/1)
      |> Enum.to_list()

    registros = for {:ok, numero, tarea} <- resultados, do: {numero, tarea}
    errores = for {:error, numero, mensaje} <- resultados, do: "Línea #{numero}: #{mensaje}"
    {registros, errores}
  end

  @doc false
  def parsear({numero, linea}) do
    case String.split(linea, ";") do
      [id, duracion, plazo, dependencias] ->
        with {d, ""} <- Integer.parse(String.trim(duracion)),
             {p, ""} <- Integer.parse(String.trim(plazo)) do
          {:ok, numero,
           %Tarea{
             id: String.trim(id),
             duracion: d,
             plazo: p,
             dependencias: parsear_dependencias(String.trim(dependencias))
           }}
        else
          _ -> {:error, numero, "la duración y el plazo deben ser enteros: \"#{linea}\""}
        end

      campos ->
        {:error, numero,
         "se esperaban 4 campos separados por ';' y hay #{length(campos)}: \"#{linea}\""}
    end
  end

  defp parsear_dependencias("-"), do: []
  defp parsear_dependencias(texto), do: texto |> String.split("|") |> Enum.map(&String.trim/1)

  defp escribir_validacion(ruta, errores) do
    Archivos.abrir_salida(ruta, fn dispositivo ->
      case errores do
        [] ->
          IO.puts(dispositivo, "Sin errores: la red de tareas es válida.")

        _ ->
          IO.puts(dispositivo, "Se detectaron #{length(errores)} problema(s):")
          Enum.each(errores, fn error -> IO.puts(dispositivo, "- #{error}") end)
      end
    end)
  end

  # ------------------------------------------------------------------
  # Planificación
  # ------------------------------------------------------------------

  defp planificar([], dir_salida) do
    Util2.mostrar("Proyecto vacío: no hay tareas, no se enumeran planes.", :mensaje)

    Archivos.abrir_salida(Path.join(dir_salida, "planes.csv"), fn dispositivo ->
      IO.puts(dispositivo, "id;orden;duracion_total;penalizacion")
    end)

    Archivos.abrir_salida(Path.join(dir_salida, "resumen_tareas.txt"), fn dispositivo ->
      IO.puts(dispositivo, "Proyecto vacío: no hay tareas.")
    end)

    Svg.escribir_leyenda(Path.join(dir_salida, "mejor_plan.svg"), "Proyecto vacío: no hay plan")
  end

  defp planificar(registros, dir_salida) do
    tareas =
      registros
      |> Enum.map(fn {_numero, tarea} -> tarea end)
      |> Util2.ordenar(:asc, & &1.id)

    acumulador_inicial = %{total: 0, minimo: nil, mejores: []}

    # Cada plan se escribe en planes.csv en el momento en que la recursión lo produce.
    acumulador =
      Archivos.abrir_salida(Path.join(dir_salida, "planes.csv"), fn dispositivo ->
        IO.puts(dispositivo, "id;orden;duracion_total;penalizacion")
        buscar(tareas, 0, %{}, [], 0, acumulador_inicial, dispositivo)
      end)

    mejores = :lists.reverse(acumulador.mejores)
    escribir_resumen(Path.join(dir_salida, "resumen_tareas.txt"), acumulador, mejores)

    por_id = Map.new(tareas, fn tarea -> {tarea.id, tarea} end)
    {_id, primer_optimo} = hd(mejores)
    Svg.escribir_gantt(Path.join(dir_salida, "mejor_plan.svg"), primer_optimo, por_id)

    Util2.mostrar(
      "Total de planes: #{acumulador.total}\n" <>
        "Penalización mínima: #{acumulador.minimo}\n" <>
        "Planes con penalización mínima: #{length(mejores)}\n" <>
        "Primer plan óptimo: #{Enum.join(primer_optimo.orden, " → ")}",
      :mensaje
    )
  end

  # Recursión principal. `pendientes` está ordenada por ID, así que las tareas
  # habilitadas se prueban en orden alfabético y el resultado es reproducible.
  defp buscar([], tiempo, finalizaciones, orden_inverso, penalizacion, acumulador, dispositivo) do
    plan = %Plan{
      orden: :lists.reverse(orden_inverso),
      finalizaciones: finalizaciones,
      penalizacion: penalizacion
    }

    registrar(plan, tiempo, acumulador, dispositivo)
  end

  defp buscar(pendientes, tiempo, finalizaciones, orden_inverso, penalizacion, acumulador, dispositivo) do
    habilitadas =
      Enum.filter(pendientes, fn tarea ->
        Enum.all?(tarea.dependencias, &Map.has_key?(finalizaciones, &1))
      end)

    Enum.reduce(habilitadas, acumulador, fn tarea, acc ->
      fin = tiempo + tarea.duracion
      penalizacion_tarea = max(0, fin - tarea.plazo)

      buscar(
        List.delete(pendientes, tarea),
        fin,
        Map.put(finalizaciones, tarea.id, fin),
        [tarea.id | orden_inverso],
        penalizacion + penalizacion_tarea,
        acc,
        dispositivo
      )
    end)
  end

  defp registrar(plan, duracion_total, acumulador, dispositivo) do
    id = acumulador.total + 1

    IO.puts(
      dispositivo,
      "#{id};#{Enum.join(plan.orden, " → ")};#{duracion_total};#{plan.penalizacion}"
    )

    acumulador = %{acumulador | total: id}

    cond do
      acumulador.minimo == nil or plan.penalizacion < acumulador.minimo ->
        %{acumulador | minimo: plan.penalizacion, mejores: [{id, plan}]}

      plan.penalizacion == acumulador.minimo ->
        %{acumulador | mejores: [{id, plan} | acumulador.mejores]}

      true ->
        acumulador
    end
  end

  defp escribir_resumen(ruta, acumulador, mejores) do
    Archivos.abrir_salida(ruta, fn dispositivo ->
      IO.puts(dispositivo, "Total de planes: #{acumulador.total}")
      IO.puts(dispositivo, "Penalización mínima: #{acumulador.minimo}")
      IO.puts(dispositivo, "Planes que la alcanzan (#{length(mejores)}):")

      IO.write(
        dispositivo,
        Util2.convertir_coleccion_mensaje(mejores, fn {id, plan} ->
          " - Plan #{id}: #{Enum.join(plan.orden, " → ")}\n"
        end)
      )
    end)
  end
end
