### Economic dispatch without renewable energy sources
function EconomicDispatch(time,
						  nodes::Nodes,
			   		      powerplants::PowerPlants,
			   			  )

	G = powerplants.unit
	T = time

	# Initialise JuMP model: Economic dispatch
	ED_mod = JuMP.Model(with_optimizer(Gurobi.Optimizer))

	# Variables
	@variable(ED_mod, P[T, G] >= 0)

	# Constraints
	# Market clearing/power balance
	@constraint(ED_mod, MarketClearing[t = T],
	    sum(P[t, g] for g in G) == nodes.systemload[t]);

	# Upper generation limit
	@constraint(ED_mod, GenerationLimitUp[g = G, t = T],
	    P[t, g] <= powerplants.pmax[g]);

	# Lower generation limit
	@constraint(ED_mod, GenerationLimitDown[g = G, t = T],
	    P[t, g] >= powerplants.pmin[g]);

	# Ramp-up limit
	@constraint(ED_mod, RampUp[g = G, t = T; t > T[1]],
		P[t, g] - P[t-1, g] <= powerplants.rup[g])

	# Ramp-down limit
	@constraint(ED_mod, RampDown[g = G, t = T; t > T[1]],
		-(P[t, g] - P[t-1, g]) <= powerplants.rdn[g])

	# Objective function
	@objective(ED_mod, Min,
	    sum(powerplants.mc[g][1] * P[t, g] for g in G, t in T));

	# Initiate optimisation process
	JuMP.optimize!(ED_mod)

	# Export results
	P_opt = JuMP.value.(P)
	price = JuMP.dual.(MarketClearing)

	return(ED_mod,
	       P_opt,
		   price
	       )
end

### Economic dispatch with renewable energy sources
function EconomicDispatch(time,
						  nodes::Nodes,
			   		      powerplants::PowerPlants,
						  renewables::Renewables,
			   			  )

	T = time
	G = powerplants.unit
	R = renewables.unit

	# Initialise JuMP model: Economic dispatch
	ED_mod = JuMP.Model(with_optimizer(Gurobi.Optimizer))

	# Variables
	@variable(ED_mod, P[T, G] >= 0)
	@variable(ED_mod, P_R[T, R] >= 0)

	# Constraints
	# Market clearing/power balance
	@constraint(ED_mod, MarketClearing[t = T],
	    sum(P[t, g] for g in G) +
			sum(P_R[t, r] for r in R) == nodes.systemload[t]);

	# Upper generation limit
	@constraint(ED_mod, GenerationLimitUp[g = G, t = T],
	    P[t, g] <= powerplants.pmax[g]);

	# Lower generation limit
	@constraint(ED_mod, GenerationLimitDown[g = G, t = T],
	    P[t, g] >= powerplants.pmin[g]);

	# Upper generation limit for renewables
	@constraint(ED_mod, ResGenerationLimitUp[r = R, t = T],
	    P_R[t, r] <= renewables.generation[r][t]);

	# Ramp-up limit
	@constraint(ED_mod, RampUp[g = G, t = T; t > T[1]],
		P[t, g] - P[t-1, g] <= powerplants.rup[g])

	# Ramp-down limit
	@constraint(ED_mod, RampDown[g = G, t = T; t > T[1]],
		-(P[t, g] - P[t-1, g]) <= powerplants.rdn[g])

	# Objective function
	@objective(ED_mod, Min,
	    sum(powerplants.mc[g][1] * P[t, g] for g in G, t in T) +
			sum(renewables.mc[r] * P_R[t, r] for r in R, t in T));

	# Initiate optimisation process
	JuMP.optimize!(ED_mod)

	# Export results
	P_opt = JuMP.value.(P)
	P_R_opt = JuMP.value.(P_R)
	price = JuMP.dual.(MarketClearing)

	# Correct RES dispatch
	# Total summed RES generation from dispatch for each t
	ResTotalGeneration = zeros(length(T), 1)

	for t in T
		ResTotalGeneration[t-(T[1]-1)] = sum(P_R_opt.data[t-(T[1]-1), :])
	end

	# Maximum output possible
	ResMaxGeneration = zeros(length(T), 1)
	for t in T
		ResMaxGeneration[t-(T[1]-1)] = sum(renewables.generation[r][t] for r in R)
	end

	# Redistribution among RES
	ResUnitGeneration = zeros(length(T), length(R))
	for t in T
		for r in R
			ResUnitGeneration[t-(T[1]-1), r] = (renewables.generation[r][t] / ResMaxGeneration[t-(T[1]-1)]) *
			ResTotalGeneration[t-(T[1]-1)]
		end
	end

	# Distributed, corrected P_R_opt
	P_R_opt_dist = JuMP.Containers.DenseAxisArray(ResUnitGeneration, T, R)

	return(ED_mod,
	       P_opt,
		   P_R_opt,
		   P_R_opt_dist,
		   price
	       )
end
