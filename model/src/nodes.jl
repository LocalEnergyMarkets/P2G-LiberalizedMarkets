# This file contains the definition for the nodes struct.

mutable struct Nodes
	id
	systemload
	load
	bmva
	slack

	function Nodes(nodes_df::DataFrame,
				   load_df::DataFrame
				   )

		# Initialise dataframe, including all nodes with zeros
		load_full = DataFrame(zeros(length(load_df[!, 1]),
										   length(nodes_df[!, 1])
									)
							 , Symbol.(nodes_df[!, 1])
							 )

		systemload = load_df[!, 1]

		# Calculate the absolute load at a node
		for col in 2:ncol(load_df)
			load_df[!, col] = load_df[!, col] .* load_df[!, 1]
		end

		load_df = load_df[!, 2:end]

		for col in names(load_df)
			load_full[!, col] = load_df[!, col]
		end

		N = parse.(Int,String.(names(load_full)))
		load_dict = Dict(N[col] => load_full[!, col] for col in 1:length(N))

		bmva = nodes_df[1, :bmva]
		slack = nodes_df[1, :slack]

		return new(N,
				   systemload,
				   load_dict,
				   bmva,
				   slack
				   )
	end
end
