# This file contains the definition for the Lines struct.

mutable struct Lines
    id
    from
    to
	reactance
	pmax

    function Lines(lines_df::DataFrame)

		# Zbase = (Vbase*1e3)^2/(Sbase*1e6)

		L = lines_df[!, 1]                                    # U = unit
        lines_dict = df_to_dict_with_id(lines_df)

		# lines_dict[:reactance] = lines_dict[:reactance] ./
		# 	lines_dict[:circuits] ./ Zbase

        return new(L,
                   lines_dict[:from],
                   lines_dict[:to],
				   lines_dict[:reactance],
                   lines_dict[:pmax],
				   )
    end
end
