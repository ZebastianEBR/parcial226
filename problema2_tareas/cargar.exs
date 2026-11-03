# Carga los módulos del problema 2 en el orden correcto (los structs primero).
raiz = Path.expand("..", __DIR__)

[
  Path.join(raiz, "Util2.ex"),
  Path.join(raiz, "compartido/archivos.ex"),
  Path.join(__DIR__, "lib/structs.ex"),
  Path.join(__DIR__, "lib/validacion.ex"),
  Path.join(__DIR__, "lib/svg.ex"),
  Path.join(__DIR__, "lib/tareas.ex")
]
|> Enum.each(fn ruta ->
  if File.regular?(ruta) do
    Code.require_file(ruta)
  else
    IO.puts(:standard_error, "No se encontró #{ruta}. Si es Util2.ex, cópielo en la carpeta raíz del repositorio.")
    System.halt(1)
  end
end)
