defmodule Parcial2.ParentesisTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO

  alias Parcial2.Parentesis

  defp datos(nombre), do: Path.expand("../" <> nombre, __DIR__)

  test "n=3, p=2 produce las 4 cadenas esperadas, en orden" do
    assert Enum.to_list(Parentesis.generar(3, 2)) ==
             ["(()())", "(())()", "()(())", "()()()"]
  end

  test "sin restricción efectiva el total es el número de Catalan" do
    assert Parentesis.contar(4, 4) == 14
    assert Parentesis.contar(8, 8) == 1430
  end

  test "la profundidad restringe las soluciones" do
    assert Parentesis.contar(3, 1) == 1
    assert Enum.to_list(Parentesis.generar(3, 1)) == ["()()()"]
  end

  test "caso límite: n=1" do
    assert Enum.to_list(Parentesis.generar(1, 1)) == ["()"]
  end

  test "es perezoso: la primera solución de n=18, p=18 no calcula las demás" do
    esperado = String.duplicate("(", 18) <> String.duplicate(")", 18)
    assert Enum.take(Parentesis.generar(18, 18), 1) == [esperado]
  end

  test "el Stream infinito se detiene en n=8 (1430) y nunca calcula n=9" do
    assert List.last(Enum.to_list(Parentesis.secuencia(1000))) == {8, 1430}
    assert length(Enum.to_list(Parentesis.secuencia(1000))) == 8
  end

  test "motivos: cadena válida" do
    assert Parentesis.motivos(3, 2, "(()())") == []
  end

  test "motivos: profundidad excedida" do
    [motivo] = Parentesis.motivos(3, 2, "((()))")
    assert motivo =~ "profundidad"
    assert motivo =~ "(((" 
  end

  test "motivos: cierra de más y no termina en cero" do
    motivos = Parentesis.motivos(3, 2, "())(()")
    assert length(motivos) == 2
    assert Enum.any?(motivos, &(&1 =~ "primer prefijo problemático"))
    assert Enum.any?(motivos, &(&1 =~ "balance 1"))
  end

  test "motivos: longitud y símbolo incorrectos" do
    motivos = Parentesis.motivos(2, 2, "(a)")
    assert Enum.any?(motivos, &(&1 =~ "longitud"))
    assert Enum.any?(motivos, &(&1 =~ "símbolo"))
  end

  @tag :tmp_dir
  test "ejecutar con datos válidos escribe los archivos", %{tmp_dir: tmp} do
    capture_io(fn -> Parentesis.ejecutar(datos("datos"), tmp) end)

    assert File.read!(Path.join(tmp, "parentesis_n3_p2.txt")) ==
             "(()())\n(())()\n()(())\n()()()\nTotal: 4\n"

    assert File.read!(Path.join(tmp, "secuencia_parentesis.csv")) |> String.ends_with?("8;1430\n")
    assert File.exists?(Path.join(tmp, "primera_n18_p18.txt"))
    verificacion = File.read!(Path.join(tmp, "verificacion_parentesis.txt"))
    assert verificacion =~ "-> VÁLIDA"
    assert verificacion =~ "-> INVÁLIDA"
  end

  @tag :tmp_dir
  test "datos inválidos se reportan sin excepción", %{tmp_dir: tmp} do
    errores = capture_io(:stderr, fn -> capture_io(fn -> Parentesis.ejecutar(datos("datos_invalidos"), tmp) end) end)
    assert errores =~ "línea 2"
    assert File.exists?(Path.join(tmp, "parentesis_n3_p2.txt"))
    refute File.exists?(Path.join(tmp, "parentesis_n0_p1.txt"))
  end

  @tag :tmp_dir
  test "carpeta inexistente muestra aviso", %{tmp_dir: tmp} do
    errores = capture_io(:stderr, fn -> capture_io(fn -> Parentesis.ejecutar(datos("no_existe"), tmp) end) end)
    assert errores =~ "AVISO"
  end
end
