# Carga los módulos del problema 4.
raiz = Path.expand("..", __DIR__)

[
  Path.join(raiz, "Util2.ex"),
  Path.join(raiz, "compartido/archivos.ex"),
  Path.join(__DIR__, "lib/parentesis.ex")
]
|> Enum.each(fn ruta ->
  if File.regular?(ruta) do
    Code.require_file(ruta)
  else
    IO.puts(:standard_error, "No se encontró #{ruta}. Si es Util2.ex, cópielo en la carpeta raíz del repositorio.")
    System.halt(1)
  end
end)
