# Carga (compila en memoria) todos los módulos del proyecto en el orden correcto.
# Los structs deben cargarse antes que los módulos que los usan.
base = __DIR__

[
  "util2.ex",
  "lib/parcial2/structs.ex",
  "lib/parcial2/archivos.ex",
  "lib/parcial2/tareas/validacion.ex",
  "lib/parcial2/tareas/svg.ex",
  "lib/parcial2/tareas.ex",
  "lib/parcial2/parentesis.ex",
  "lib/parcial2.ex"
]
|> Enum.each(fn archivo ->
  ruta = Path.join(base, archivo)

  if File.regular?(ruta) do
    Code.require_file(ruta)
  else
    IO.puts(:standard_error, "No se encontró #{archivo}. Si es util2.ex, cópielo en la carpeta raíz del proyecto.")
    System.halt(1)
  end
end)
