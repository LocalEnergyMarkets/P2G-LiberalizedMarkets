# This file contains the definition for the PowerPlants struct.

mutable struct PowerPlants
    unit
    node
    pmax
    pmin
    rup
    rdn
    timeup
    timedn
    mc
    varcost
    fuel
    efficiency
    emission

    function PowerPlants(pp_df::DataFrame)

        G = pp_df[!, 1]                                    # U = unit
        pp_dict = df_to_dict_with_id(pp_df)

        return new(G,
                   pp_dict[:node],
                   pp_dict[:pmax],
                   pp_dict[:pmin],
                   pp_dict[:rup],
                   pp_dict[:rdn],
                   pp_dict[:timeup],
                   pp_dict[:timedn],
                   pp_dict[:mc],
                   0,
                   0,
                   0,
                   0,
                   )
    end

    function PowerPlants(pp_df::DataFrame, fuelcost_df::DataFrame)

        G = pp_df[!, 1]                                    # U = unit
        pp_dict = df_to_dict_with_id(pp_df)

        # Marginal generation cost from fuel cost, efficiency, variable cost
        # and CO2 price

        fuelcost_dict = df_to_dict(fuelcost_df)
        mc = Dict{Int64, Array{Float64, 1}}()

        for p in keys(pp_dict[:fuel])
            f = Symbol(pp_dict[:fuel][p])
            fuelcost = fuelcost_dict[f]
            η = pp_dict[:efficiency][p]
            co_price = fuelcost_dict[:CO2]
            emission = pp_dict[:emission][p]
            vc = pp_dict[:varcost][p]

            mc[p] = fuelcost / η + co_price * emission .+ vc
        end

        return new(G,
                   pp_dict[:node],
                   pp_dict[:pmax],
                   pp_dict[:pmin],
                   pp_dict[:rup],
                   pp_dict[:rdn],
                   pp_dict[:timeup],
                   pp_dict[:timedn],
                   mc,
                   pp_dict[:varcost],
                   pp_dict[:fuel],
                   pp_dict[:efficiency],
                   pp_dict[:emission]
                   )
    end
end
