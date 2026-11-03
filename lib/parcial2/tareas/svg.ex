defmodule Parcial2.Tareas.Svg do
  @moduledoc """
  Diagrama de Gantt en SVG. El documento se escribe por fragmentos
  (una línea / un elemento a la vez), nunca como un único string.
  """

  alias Parcial2.Archivos

  @escala 30
  @izquierda 70
  @derecha 170
  @arriba 60
  @alto_fila 40

  @doc "Dibuja el Gantt de un plan. `por_id` es `%{id => %Parcial2.Tarea{}}`."
  def escribir_gantt(ruta, plan, por_id) do
    total = fin_total(plan)
    filas = length(plan.orden)
    ancho = @izquierda + total * @escala + @derecha
    alto = @arriba + filas * @alto_fila + 70

    Archivos.abrir_salida(ruta, fn dev ->
      abrir(dev, ancho, alto)
      IO.puts(dev, ~s|<rect width="#{ancho}" height="#{alto}" fill="white"/>|)

      IO.puts(
        dev,
        ~s|<text x="10" y="24" font-size="16" font-family="sans-serif" font-weight="bold">| <>
          esc("Mejor plan — penalización #{plan.penalizacion}, duración total #{total}") <>
          "</text>"
      )

      eje(dev, total, filas)

      plan.orden
      |> Enum.with_index()
      |> Enum.each(fn {id, indice} ->
        barra(dev, Map.fetch!(por_id, id), Map.fetch!(plan.finalizaciones, id), indice)
      end)

      leyenda(dev, alto - 40)
      IO.puts(dev, "</svg>")
    end)
  end

  @doc "SVG con un único mensaje explicativo."
  def escribir_leyenda(ruta, mensaje) do
    Archivos.abrir_salida(ruta, fn dev ->
      abrir(dev, 560, 80)
      IO.puts(dev, ~s|<rect width="560" height="80" fill="white"/>|)

      IO.puts(
        dev,
        ~s|<text x="20" y="45" font-size="16" font-family="sans-serif">| <> esc(mensaje) <> "</text>"
      )

      IO.puts(dev, "</svg>")
    end)
  end

  defp abrir(dev, ancho, alto) do
    IO.puts(dev, ~s|<?xml version="1.0" encoding="UTF-8"?>|)

    IO.puts(
      dev,
      ~s|<svg xmlns="http://www.w3.org/2000/svg" width="#{ancho}" height="#{alto}" viewBox="0 0 #{ancho} #{alto}">|
    )
  end

  defp fin_total(plan), do: plan.finalizaciones |> Map.values() |> Enum.max()

  defp eje(dev, total, filas) do
    paso = max(1, div(total + 19, 20))
    y_final = @arriba + filas * @alto_fila

    Enum.each(0..total, fn t ->
      x = @izquierda + t * @escala
      IO.puts(dev, ~s|<line x1="#{x}" y1="#{@arriba - 5}" x2="#{x}" y2="#{y_final}" stroke="#dddddd"/>|)

      if rem(t, paso) == 0 do
        IO.puts(
          dev,
          ~s|<text x="#{x}" y="#{@arriba - 10}" font-size="11" text-anchor="middle" font-family="sans-serif">#{t}</text>|
        )
      end
    end)
  end

  defp barra(dev, tarea, fin, indice) do
    inicio = fin - tarea.duracion
    tarde = fin > tarea.plazo
    x = @izquierda + inicio * @escala
    y = @arriba + indice * @alto_fila + 6
    color = if tarde, do: "#d9534f", else: "#5cb85c"
    etiqueta = "#{inicio}–#{fin}" <> if(tarde, do: " (tarde, plazo #{tarea.plazo})", else: "")

    IO.puts(
      dev,
      ~s|<text x="#{@izquierda - 8}" y="#{y + 19}" font-size="13" text-anchor="end" font-family="sans-serif">| <>
        esc(tarea.id) <> "</text>"
    )

    IO.puts(
      dev,
      ~s|<rect x="#{x}" y="#{y}" width="#{tarea.duracion * @escala}" height="28" fill="#{color}" stroke="#333333"/>|
    )

    IO.puts(
      dev,
      ~s|<text x="#{x + tarea.duracion * @escala + 6}" y="#{y + 19}" font-size="12" font-family="sans-serif">| <>
        esc(etiqueta) <> "</text>"
    )
  end

  defp leyenda(dev, y) do
    IO.puts(dev, ~s|<rect x="10" y="#{y}" width="16" height="16" fill="#5cb85c" stroke="#333333"/>|)
    IO.puts(dev, ~s|<text x="32" y="#{y + 13}" font-size="12" font-family="sans-serif">Dentro del plazo</text>|)
    IO.puts(dev, ~s|<rect x="160" y="#{y}" width="16" height="16" fill="#d9534f" stroke="#333333"/>|)
    IO.puts(dev, ~s|<text x="182" y="#{y + 13}" font-size="12" font-family="sans-serif">Terminada fuera de plazo</text>|)
  end

  # Escapa texto para XML.
  defp esc(texto) do
    texto
    |> to_string()
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&apos;")
  end
end
