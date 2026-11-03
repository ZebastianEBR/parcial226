defmodule Parcial2.Tarea do
  @moduledoc "Tarea del proyecto (problema 2)."
  defstruct [:id, :duracion, :plazo, dependencias: []]
end

defmodule Parcial2.Plan do
  @moduledoc """
  Orden válido de ejecución.

  - `orden`: lista de IDs en el orden de ejecución.
  - `finalizaciones`: mapa `%{id => tiempo_de_finalizacion}`.
  - `penalizacion`: suma de `max(0, finalizacion - plazo)`.
  """
  defstruct [:orden, :finalizaciones, :penalizacion]
end
