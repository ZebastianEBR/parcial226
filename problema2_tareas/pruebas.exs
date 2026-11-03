# Pruebas del problema 2.  Ejecutar:  elixir problema2_tareas/pruebas.exs
ExUnit.start()
Code.require_file(Path.join(__DIR__, "cargar.exs"))
Code.require_file(Path.join(__DIR__, "pruebas/tareas_test.exs"))
