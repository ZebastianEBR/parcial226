defmodule Parcial2 do
  @moduledoc """
  Programa principal del Parcial 2 (Programación III).

  Problemas resueltos:

  - Problema 2: planificación de tareas con dependencias.
  - Problema 4: secuencias de paréntesis balanceados.

  Se ejecuta con `elixir principal.exs`.
  """

  alias Parcial2.{Parentesis, Tareas}

  def main do
    Util2.mostrar("=== Parcial 2 - Programación III ===", :mensaje)

    datos = preguntar_ruta("Carpeta de datos [datos]: ", "datos")
    salida = preguntar_ruta("Carpeta de salida [salida]: ", "salida")

    menu(datos, salida)
  end

  defp preguntar_ruta(pregunta, defecto) do
    case Util2.ingresar(pregunta, :String) do
      "" -> defecto
      ruta -> ruta
    end
  end

  defp menu(datos, salida) do
    Util2.mostrar(
      """

      1. Problema 2 - Planificación de tareas
      2. Problema 4 - Paréntesis balanceados
      3. Ejecutar ambos
      0. Salir
      """,
      :mensaje
    )

    case Util2.ingresar("Opción: ", :int) do
      1 ->
        Tareas.ejecutar(datos, salida)
        menu(datos, salida)

      2 ->
        Parentesis.ejecutar(datos, salida)
        menu(datos, salida)

      3 ->
        Tareas.ejecutar(datos, salida)
        Parentesis.ejecutar(datos, salida)
        menu(datos, salida)

      0 ->
        Util2.mostrar("Hasta luego.", :mensaje)

      _ ->
        Util2.mostrar("Opción no válida.", :error)
        menu(datos, salida)
    end
  end
end
