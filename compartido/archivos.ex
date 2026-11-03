defmodule Parcial2.Archivos do
  @moduledoc """
  Utilidades comunes de lectura en flujo y escritura de archivos.
  """

  @doc """
  Verifica que exista un archivo requerido. Si no existe muestra un aviso
  (sin lanzar excepción) y retorna `false`.
  """
  def existe?(ruta, descripcion) do
    if File.regular?(ruta) do
      true
    else
      Util2.mostrar("AVISO: no se encontró el archivo #{descripcion}: #{ruta}", :error)
      false
    end
  end

  @doc """
  Retorna un Stream perezoso de `{numero_de_linea_fisica, texto}` que ignora
  líneas en blanco y comentarios (primer carácter no blanco igual a `#`).
  """
  def lineas_utiles(ruta) do
    ruta
    |> File.stream!()
    |> Stream.with_index(1)
    |> Stream.map(fn {linea, numero} -> {numero, String.trim(linea)} end)
    |> Stream.reject(fn {_numero, linea} ->
      linea == "" or String.starts_with?(linea, "#")
    end)
  end

  @doc """
  Crea (o reemplaza) un archivo de salida y ejecuta `funcion` con el
  dispositivo abierto, para escribir progresivamente. Crea la carpeta si
  hace falta. Retorna lo que retorne `funcion`.
  """
  def abrir_salida(ruta, funcion) do
    File.mkdir_p!(Path.dirname(ruta))
    File.open!(ruta, [:write, :utf8], funcion)
  end
end
