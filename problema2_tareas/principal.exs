# PROBLEMA 2 - Planificación de tareas con dependencias.
# Ejecutar desde la raíz del repositorio:  elixir problema2_tareas/principal.exs
Code.require_file(Path.join(__DIR__, "cargar.exs"))

pedir = fn pregunta, defecto ->
  case Util2.ingresar(pregunta, :String) do
    "" -> Path.join(__DIR__, defecto)
    ruta -> Path.expand(ruta, __DIR__)
  end
end

Util2.mostrar("=== Problema 2: planificación de tareas ===", :mensaje)
datos = pedir.("Carpeta de datos [datos]: ", "datos")
salida = pedir.("Carpeta de salida [salida]: ", "salida")
Parcial2.Tareas.ejecutar(datos, salida)
Util2.mostrar("Archivos generados en: #{salida}", :mensaje)
