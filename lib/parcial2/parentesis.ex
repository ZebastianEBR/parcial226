defmodule Parcial2.Parentesis do
  @moduledoc """
  Problema 4: secuencias de paréntesis balanceados con profundidad máxima.

  - `generar/2` produce un Stream perezoso y recursivo de soluciones.
  - `motivos/3` valida recursivamente una cadena propuesta.
  - `secuencia/1` es el Stream infinito n = 1, 2, 3... con p = n.
  """

  alias Parcial2.Archivos

  @umbral 1000

  # ------------------------------------------------------------------
  # Generador recursivo y perezoso
  # ------------------------------------------------------------------

  @doc """
  Stream de todas las cadenas balanceadas con `n` pares y profundidad
  máxima `p`, en el orden que resulta de intentar primero `(` y luego `)`.

  Nada se calcula hasta que el Stream se consume: cada rama es un
  `Stream.flat_map` que se evalúa solo cuando el consumidor la necesita.
  """
  def generar(n, p), do: construir("", 0, 0, n, p)

  # Caso base: ya se cerraron n paréntesis, el prefijo es una solución.
  defp construir(prefijo, _abiertos, cerrados, n, _p) when cerrados == n, do: [prefijo]

  defp construir(prefijo, abiertos, cerrados, n, p) do
    Stream.concat(
      # Primero intentar "(": quedan por abrir y no se excede la profundidad.
      Stream.flat_map([:abrir], fn _ ->
        if abiertos < n and abiertos - cerrados < p do
          construir(prefijo <> "(", abiertos + 1, cerrados, n, p)
        else
          []
        end
      end),
      # Luego intentar ")": hay algún paréntesis abierto pendiente.
      Stream.flat_map([:cerrar], fn _ ->
        if cerrados < abiertos do
          construir(prefijo <> ")", abiertos, cerrados + 1, n, p)
        else
          []
        end
      end)
    )
  end

  @doc "Cuenta las soluciones consumiendo el Stream sin guardarlas."
  def contar(n, p), do: Enum.reduce(generar(n, p), 0, fn _solucion, total -> total + 1 end)

  # ------------------------------------------------------------------
  # Ejecución general
  # ------------------------------------------------------------------

  def ejecutar(dir_datos, dir_salida) do
    Util2.mostrar("\n--- Problema 4: paréntesis balanceados ---", :mensaje)
    procesar_parametros(dir_datos, dir_salida)
    escribir_primera(dir_salida)
    verificar_propuestas(dir_datos, dir_salida)
    escribir_secuencia(dir_salida)
    :ok
  end

  # ------------------------------------------------------------------
  # parametros.csv -> parentesis_n<N>_p<P>.txt
  # ------------------------------------------------------------------

  def procesar_parametros(dir_datos, dir_salida) do
    ruta = Path.join(dir_datos, "parametros.csv")

    if Archivos.existe?(ruta, "de parámetros") do
      ruta
      |> Archivos.lineas_utiles()
      |> Stream.map(&parsear_parametro/1)
      |> Enum.each(fn
        {:ok, n, p} ->
          salida = Path.join(dir_salida, "parentesis_n#{n}_p#{p}.txt")
          total = escribir_soluciones(n, p, salida)
          Util2.mostrar("n=#{n}, p=#{p}: total = #{total}", :mensaje)

        {:error, numero, mensaje} ->
          Util2.mostrar("parametros.csv, línea #{numero}: #{mensaje}", :error)
      end)
    end
  end

  @doc false
  def parsear_parametro({numero, linea}) do
    case String.split(linea, ";") do
      [a, b] ->
        with {n, ""} <- Integer.parse(String.trim(a)),
             {p, ""} <- Integer.parse(String.trim(b)),
             true <- n >= 1 and p >= 1 and p <= n do
          {:ok, n, p}
        else
          _ ->
            {:error, numero,
             "se requiere n >= 1 y 1 <= profundidad_max <= n, recibido: \"#{linea}\""}
        end

      _ ->
        {:error, numero, "formato inválido, se esperaba n;profundidad_max: \"#{linea}\""}
    end
  end

  @doc "Escribe una solución por línea, a medida que se consume el Stream, y el total al final."
  def escribir_soluciones(n, p, ruta) do
    Archivos.abrir_salida(ruta, fn dispositivo ->
      total =
        Enum.reduce(generar(n, p), 0, fn solucion, acumulado ->
          IO.puts(dispositivo, solucion)
          acumulado + 1
        end)

      IO.puts(dispositivo, "Total: #{total}")
      total
    end)
  end

  # ------------------------------------------------------------------
  # Primera solución de n=18, p=18 (solo un elemento del Stream)
  # ------------------------------------------------------------------

  def escribir_primera(dir_salida) do
    ruta = Path.join(dir_salida, "primera_n18_p18.txt")

    case Enum.take(generar(18, 18), 1) do
      [solucion] ->
        Archivos.abrir_salida(ruta, fn dispositivo -> IO.puts(dispositivo, solucion) end)
        Util2.mostrar("Primera solución n=18, p=18: #{solucion}", :mensaje)

      [] ->
        Util2.mostrar("No hay soluciones para n=18, p=18.", :error)
    end
  end

  # ------------------------------------------------------------------
  # Validación recursiva de cadenas propuestas
  # ------------------------------------------------------------------

  def verificar_propuestas(dir_datos, dir_salida) do
    ruta = Path.join(dir_datos, "propuestas.txt")

    if Archivos.existe?(ruta, "de propuestas") do
      salida = Path.join(dir_salida, "verificacion_parentesis.txt")

      Archivos.abrir_salida(salida, fn dispositivo ->
        ruta
        |> Archivos.lineas_utiles()
        |> Enum.each(fn {numero, linea} -> verificar_linea(dispositivo, numero, linea) end)
      end)

      Util2.mostrar("Verificación escrita en #{salida}", :mensaje)
    end
  end

  defp verificar_linea(dispositivo, numero, linea) do
    with [a, b, cadena] <- String.split(linea, ";", parts: 3),
         {n, ""} <- Integer.parse(String.trim(a)),
         {p, ""} <- Integer.parse(String.trim(b)) do
      cadena = String.trim(cadena)

      case motivos(n, p, cadena) do
        [] ->
          IO.puts(dispositivo, "Línea #{numero}: n=#{n}, p=#{p}, \"#{cadena}\" -> VÁLIDA")

        lista ->
          IO.puts(dispositivo, "Línea #{numero}: n=#{n}, p=#{p}, \"#{cadena}\" -> INVÁLIDA")

          IO.write(
            dispositivo,
            Util2.convertir_coleccion_mensaje(lista, fn motivo -> "    - #{motivo}\n" end)
          )
      end
    else
      _ ->
        IO.puts(dispositivo, "Línea #{numero}: registro mal formado, se esperaba n;p;cadena: \"#{linea}\"")
    end
  end

  @doc """
  Retorna la lista de motivos por los que `cadena` no es una solución válida
  para `(n, p)`. Lista vacía significa válida.
  """
  def motivos(n, p, cadena) do
    info = analizar(cadena, p)

    motivo_longitud(n, cadena) ++
      motivo_simbolo(info) ++
      motivo_cierre(info, cadena) ++
      motivo_balance(info) ++
      motivo_profundidad(info, p, cadena)
  end

  defp motivo_longitud(n, cadena) do
    if String.length(cadena) == 2 * n,
      do: [],
      else: ["la longitud es #{String.length(cadena)} y debería ser #{2 * n} (2n)"]
  end

  defp motivo_simbolo(%{simbolo: nil}), do: []

  defp motivo_simbolo(%{simbolo: {pos, car}}),
    do: ["contiene el símbolo no permitido \"#{car}\" en la posición #{pos}"]

  defp motivo_cierre(%{cierre: nil}, _cadena), do: []

  defp motivo_cierre(%{cierre: pos}, cadena),
    do: [
      "cierra más paréntesis de los abiertos; primer prefijo problemático: " <>
        "\"#{String.slice(cadena, 0, pos + 1)}\" (posición #{pos})"
    ]

  defp motivo_balance(%{balance: 0}), do: []

  defp motivo_balance(%{balance: b}),
    do: ["termina con balance #{b} en lugar de 0"]

  defp motivo_profundidad(%{exceso: nil}, _p, _cadena), do: []

  defp motivo_profundidad(%{exceso: pos, maxprof: maxprof}, p, cadena),
    do: [
      "excede la profundidad máxima p=#{p}: alcanza #{maxprof}; primer prefijo que la excede: " <>
        "\"#{String.slice(cadena, 0, pos + 1)}\" (posición #{pos})"
    ]

  @doc """
  Recorre recursivamente la cadena (sin Enum ni Stream) acumulando balance,
  profundidad máxima, primer cierre indebido, primer exceso de profundidad
  y primer símbolo no permitido.
  """
  def analizar(cadena, p),
    do: recorrer(cadena, 0, 0, 0, p, %{cierre: nil, exceso: nil, simbolo: nil})

  defp recorrer(<<>>, _pos, balance, maxprof, _p, info),
    do: Map.merge(info, %{balance: balance, maxprof: maxprof})

  defp recorrer(<<"(", resto::binary>>, pos, balance, maxprof, p, info) do
    nuevo = balance + 1
    info = if nuevo > p and info.exceso == nil, do: %{info | exceso: pos}, else: info
    recorrer(resto, pos + 1, nuevo, Kernel.max(maxprof, nuevo), p, info)
  end

  defp recorrer(<<")", resto::binary>>, pos, 0, maxprof, p, info) do
    # Cierre sin paréntesis abierto: se anota la primera vez y el balance no baja de 0.
    info = if info.cierre == nil, do: %{info | cierre: pos}, else: info
    recorrer(resto, pos + 1, 0, maxprof, p, info)
  end

  defp recorrer(<<")", resto::binary>>, pos, balance, maxprof, p, info),
    do: recorrer(resto, pos + 1, balance - 1, maxprof, p, info)

  defp recorrer(<<car::utf8, resto::binary>>, pos, balance, maxprof, p, info) do
    info = if info.simbolo == nil, do: %{info | simbolo: {pos, <<car::utf8>>}}, else: info
    recorrer(resto, pos + 1, balance, maxprof, p, info)
  end

  # ------------------------------------------------------------------
  # Stream infinito: crecimiento de soluciones
  # ------------------------------------------------------------------

  @doc """
  Stream de `{n, total}` con p = n, que se detiene después del primer n
  cuyo total sea >= `umbral` (incluyéndolo).

  El conteo de cada n se hace *dentro* de `Stream.transform`: cuando se
  recibe el siguiente n (9 en el ejemplo) ya se sabe que hay que parar y se
  retorna `:halt` sin ejecutar `contar/2`, por eso n=9 nunca se calcula.
  """
  def secuencia(umbral \\ @umbral) do
    Stream.iterate(1, &(&1 + 1))
    |> Stream.transform(false, fn
      _n, true ->
        {:halt, true}

      n, false ->
        total = contar(n, n)
        {[{n, total}], total >= umbral}
    end)
  end

  def escribir_secuencia(dir_salida, umbral \\ @umbral) do
    ruta = Path.join(dir_salida, "secuencia_parentesis.csv")

    Archivos.abrir_salida(ruta, fn dispositivo ->
      IO.puts(dispositivo, "n;total")

      Enum.each(secuencia(umbral), fn {n, total} ->
        IO.puts(dispositivo, "#{n};#{total}")
        Util2.mostrar("Secuencia: n=#{n}, total=#{total}", :mensaje)
      end)
    end)
  end
end
