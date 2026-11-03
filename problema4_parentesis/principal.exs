# PROBLEMA 4 - Paréntesis balanceados con profundidad máxima.
# Ejecutar desde la raíz del repositorio:  elixir problema4_parentesis/principal.exs
Code.require_file(Path.join(__DIR__, "cargar.exs"))

pedir = fn pregunta, defecto ->
  case Util2.ingresar(pregunta, :String) do
    "" -> Path.join(__DIR__, defecto)
    ruta -> Path.expand(ruta, __DIR__)
  end
end

Util2.mostrar("=== Problema 4: paréntesis balanceados ===", :mensaje)
datos = pedir.("Carpeta de datos [datos]: ", "datos")
salida = pedir.("Carpeta de salida [salida]: ", "salida")
Parcial2.Parentesis.ejecutar(datos, salida)
Util2.mostrar("Archivos generados en: #{salida}", :mensaje)
