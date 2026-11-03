# Pruebas automáticas. Ejecutar desde la carpeta raíz con:  elixir pruebas.exs
ExUnit.start()
Code.require_file(Path.join(__DIR__, "cargar.exs"))
Code.require_file(Path.join(__DIR__, "pruebas/parentesis_test.exs"))
Code.require_file(Path.join(__DIR__, "pruebas/tareas_test.exs"))
