defmodule Minecluster.Mix do
	use Mix.Project

	def project, do: [
		app: :minecluster,
		version: "0.1.0",
		deps: deps()
  ]

	defp deps, do: [
	]

	def application, do: [ mod: {App, []} ]

end
