# This file contains the definition for the Renewables struct.

mutable struct Renewables
    ﻿unit
    node
    pmax
	generation
    mc
    fuel
    name

    function Renewables(res_df::DataFrame,
                        avail_solar_df::DataFrame,
                        avail_wind_df::DataFrame)

		R = res_df[!, 1]
        RES = Vector(R)
        res_dict = df_to_dict_with_id(res_df)

		availability = [avail_solar_df avail_wind_df]

		gen_dict = Dict(RES[col] => availability[!, Symbol(res_dict[:node][col])]
			* res_dict[:pmax][col] for col in 1:length(RES))

        return new(R,
                   res_dict[:node],
                   res_dict[:pmax],
				   gen_dict,
				   res_dict[:mc],
				   res_dict[:fuel],
				   res_dict[:name],
                   )
    end
end
