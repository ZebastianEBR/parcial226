defmodule Parcial2.TareasTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO

  alias Parcial2.Tarea
  alias Parcial2.Tareas
  alias Parcial2.Tareas.Validacion

  defp datos(nombre), do: Path.expand("../" <> nombre, __DIR__)

  defp ejecutar(datos, salida) do
    capture_io(:stderr, fn -> capture_io(fn -> Tareas.ejecutar(datos, salida) end) end)
  end

  @tag :tmp_dir
  test "caso válido: dos planes, penalización mínima 4", %{tmp_dir: tmp} do
    ejecutar(datos("datos"), tmp)

    assert File.read!(Path.join(tmp, "planes.csv")) ==
             "id;orden;duracion_total;penalizacion\n" <>
               "1;A → B → C → D;10;4\n" <>
               "2;A → C → B → D;10;6\n"

    resumen = File.read!(Path.join(tmp, "resumen_tareas.txt"))
    assert resumen =~ "Total de planes: 2"
    assert resumen =~ "Penalización mínima: 4"

    svg = File.read!(Path.join(tmp, "mejor_plan.svg"))
    assert svg =~ "<svg"
    assert String.ends_with?(String.trim(svg), "</svg>")
  end

  @tag :tmp_dir
  test "caso inválido: se reportan todos los problemas y no hay planes", %{tmp_dir: tmp} do
    ejecutar(datos("datos_invalidos"), tmp)
    validacion = File.read!(Path.join(tmp, "validacion_tareas.txt"))

    assert validacion =~ "duplicado"
    assert validacion =~ "no existe"
    assert validacion =~ "depende de sí misma"
    assert validacion =~ "repetida"
    assert validacion =~ "duración"
    assert validacion =~ "A -> C -> B -> A"
    refute File.exists?(Path.join(tmp, "planes.csv"))
  end

  @tag :tmp_dir
  test "caso límite: proyecto vacío", %{tmp_dir: tmp} do
    ejecutar(datos("datos_limite"), tmp)
    assert File.read!(Path.join(tmp, "planes.csv")) == "id;orden;duracion_total;penalizacion\n"
    assert File.read!(Path.join(tmp, "resumen_tareas.txt")) =~ "Proyecto vacío"
  end

  @tag :tmp_dir
  test "archivo faltante muestra aviso", %{tmp_dir: tmp} do
    assert ejecutar(datos("no_existe"), tmp) =~ "AVISO"
  end

  test "validación: dos ciclos distintos, cada uno una sola vez" do
    registros = [
      {1, %Tarea{id: "A", duracion: 1, plazo: 1, dependencias: ["B"]}},
      {2, %Tarea{id: "B", duracion: 1, plazo: 1, dependencias: ["A", "C"]}},
      {3, %Tarea{id: "C", duracion: 1, plazo: 1, dependencias: ["B"]}}
    ]

    ciclos = Enum.filter(Validacion.validar(registros), &(&1 =~ "Ciclo"))
    assert length(ciclos) == 2
  end

  test "validación: red sin errores" do
    registros = [
      {1, %Tarea{id: "A", duracion: 1, plazo: 1, dependencias: []}},
      {2, %Tarea{id: "B", duracion: 1, plazo: 1, dependencias: ["A"]}}
    ]

    assert Validacion.validar(registros) == []
  end
end
