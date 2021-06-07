### Congestion management without renewable energy sources
function CongestionManagement(time,
							  nodes::Nodes,
							  lines::Lines,
							  price,
							  P_opt,
							  powerplants::PowerPlants,
						      )

	T = time
	G = powerplants.unit

	slack = nodes.slack
	Sbase = nodes.bmva # MVA

	lines_pmax = zeros(length(nodes.id), length(nodes.id))

	for id in lines.id
		j = lines.from[id]
		k = lines.to[id]

		lines_pmax[j, k] = lines.pmax[id]
		lines_pmax[k, j] = lines.pmax[id]
	end

	# Create the B_prime matrix in one step
	B_prime = zeros(length(nodes.id), length(nodes.id))

	for id in lines.id
		j = lines.from[id]
		k = lines.to[id]

		X = lines.reactance[id]				# reactance

		B_prime[j, k] = 1/X					# Fill YBUS with susceptance
		B_prime[k, j] = 1/X					# Symmetric matrix
	end

	for j in 1:size(B_prime)[1]
		B_prime[j, j] = -sum(B_prime[j, :])
	end

	###################
	# MODEL ###########
	###################

	# Create a subset of buses I and J
	J = nodes.id
	K = nodes.id

	# Initialise JuMP model: Congestion management
	CM_mod = JuMP.Model(with_optimizer(Gurobi.Optimizer))

	# Variables
	@variable(CM_mod, ΔP_up[T, G] >= 0)
	@variable(CM_mod, ΔP_dn[T, G] >= 0)
	@variable(CM_mod, Θ[T, J])
	@variable(CM_mod, P_inj[T, J])
	@variable(CM_mod, P_flow[T, K, J])

	# Fix the voltage angle of the slack bus
	for t in T
		fix(Θ[t, slack], 0)
	end

	# Constraints
	# Market clearing/power balance
	@constraint(CM_mod, MarketClearing[t = T],
	    sum((P_opt[t, g]/Sbase + ΔP_up[t, g] - ΔP_dn[t, g])
			for g in G) == nodes.systemload[t]/Sbase);

	# Upper generation limit
	@constraint(CM_mod, GenerationLimitUp[g = G, t = T],
	    (P_opt[t, g]/Sbase + ΔP_up[t, g] - ΔP_dn[t, g]) <=
			powerplants.pmax[g]/Sbase);

	# Lower generation limit
	@constraint(CM_mod, GenerationLimitDown[g = G, t = T],
	    (P_opt[t, g]/Sbase + ΔP_up[t, g] - ΔP_dn[t, g]) >=
			powerplants.pmin[g]/Sbase);

	# Ramp-up limit
	@constraint(CM_mod, RampUp[g = G, t = T; t > T[1]],
		(P_opt[t, g]/Sbase + ΔP_up[t, g] - ΔP_dn[t, g]) -
			(P_opt[t-1, g]/Sbase + ΔP_up[t-1, g] - ΔP_dn[t-1, g]) <=
			powerplants.rup[g]/Sbase)

	# Ramp-down limit
	@constraint(CM_mod, RampDown[g = G, t = T; t > T[1]],
		-((P_opt[t, g]/Sbase + ΔP_up[t, g] - ΔP_dn[t, g]) -
			(P_opt[t-1, g]/Sbase + ΔP_up[t-1, g] - ΔP_dn[t-1, g])) <=
			powerplants.rdn[g]/Sbase)

	### DC power flow constraints
	# Power injection balance
	@constraint(CM_mod, PowerInjectionBal[j = J, t = T],
		sum((P_opt[t, g]/Sbase + ΔP_up[t, g] - ΔP_dn[t, g])
			for g in getKeyVector(powerplants.node, j)) -	# all generation units connected to a node
			nodes.load[j][t]/Sbase == P_inj[t, j]);

	# Power injection angle
	@constraint(CM_mod, PowerInjectionAng[j = J, t = T],
		sum(B_prime[j, k] * (Θ[t, j] - Θ[t, k]) for k in K)
			== P_inj[t, j]);

	@constraint(CM_mod, LinePowerFlow[k = K, j = J, t = T; j != k],
		B_prime[j, k] * (Θ[t, j] - Θ[t, k]) == P_flow[t, j, k]);

	@constraint(CM_mod, LinePowerFlowMax[k = K, j = J, t = T],
		P_flow[t, j, k] <= lines_pmax[j, k]/Sbase);

	@constraint(CM_mod, LinePowerFlowMin[k = K, j = J, t = T],
		P_flow[t, j, k] >= -lines_pmax[j, k]/Sbase);

	# Objective function
	@objective(CM_mod, Min,
	    sum(powerplants.mc[g][1] * (ΔP_up[t, g]) * Sbase +
			(price[t] - powerplants.mc[g][1]) * ΔP_dn[t, g] *
				Sbase for g in G, t in T));

	# Initiate optimisation process
	JuMP.optimize!(CM_mod)

	# Export results
	ΔP_up_opt = JuMP.value.(ΔP_up) * Sbase
	ΔP_dn_opt = JuMP.value.(ΔP_dn) * Sbase
	Θ_opt = (JuMP.value.(Θ)) * 360/(2π)
	P_flow_opt = JuMP.value.(P_flow)*Sbase
	P_inj_opt = JuMP.value.(P_inj)*Sbase

	return(CM_mod,
	       ΔP_up_opt,
		   ΔP_dn_opt,
	       Θ_opt,
	       P_inj_opt,
	       P_flow_opt
	       )
end

### Congestion management with renewable energy sources
function CongestionManagement(time,
							  nodes::Nodes,
							  lines::Lines,
							  price,
							  P_opt,
						      powerplants::PowerPlants,
							  renewables::Renewables,
							  P_R_opt,
						      )

	T = time
	G = powerplants.unit
	R = renewables.unit

	slack = nodes.slack
	Sbase = nodes.bmva # MVA

	lines_pmax = zeros(length(nodes.id), length(nodes.id))

	for id in lines.id
		j = lines.from[id]
		k = lines.to[id]

		lines_pmax[j, k] = lines.pmax[id]
		lines_pmax[k, j] = lines.pmax[id]
	end

	# Create the B_prime matrix in one step
	B_prime = zeros(length(nodes.id), length(nodes.id))

	for id in lines.id
		j = lines.from[id]
		k = lines.to[id]

		X = lines.reactance[id]				# reactance

		B_prime[j, k] = 1/X					# Fill YBUS with susceptance
		B_prime[k, j] = 1/X					# Symmetric matrix
	end

	for j in 1:size(B_prime)[1]
		B_prime[j, j] = -sum(B_prime[j, :])
	end

	###################
	# MODEL ###########
	###################

	# Create a subset of buses I and J
	J = nodes.id
	K = nodes.id

	# Initialise JuMP model: Congestion management
	CM_mod = JuMP.Model(with_optimizer(Gurobi.Optimizer))

	# Variables
	@variable(CM_mod, ΔP_up[T, G] >= 0)
	@variable(CM_mod, ΔP_dn[T, G] >= 0)
	@variable(CM_mod, ΔP_R_up[T, R] == 0)
	@variable(CM_mod, ΔP_R_dn[T, R] >= 0)
	@variable(CM_mod, Θ[T, J])
	@variable(CM_mod, P_inj[T, J])
	@variable(CM_mod, P_flow[T, K, J])

	# Fix the voltage angle of the slack bus
	for t in T
		fix(Θ[t, slack], 0)
	end

	# Constraints
	# Market clearing/power balance
	@constraint(CM_mod, MarketClearing[t = T],
	    sum((P_opt[t, g]/Sbase + ΔP_up[t, g] - ΔP_dn[t, g]) for g in G) +
			sum((P_R_opt[t, r]/Sbase + ΔP_R_up[t, r] - ΔP_R_dn[t, r]) for r in R)
				== nodes.systemload[t]/Sbase);

	# Upper generation limit
	@constraint(CM_mod, GenerationLimitUp[g = G, t = T],
	    (P_opt[t, g]/Sbase + ΔP_up[t, g] - ΔP_dn[t, g]) <=
			powerplants.pmax[g]/Sbase);

	# Lower generation limit
	@constraint(CM_mod, GenerationLimitDown[g = G, t = T],
	    (P_opt[t, g]/Sbase + ΔP_up[t, g] - ΔP_dn[t, g]) >=
			powerplants.pmin[g]/Sbase);

	# Upper generation limit for renewables
	@constraint(CM_mod, ResGenerationLimitUp[r = R, t = T],
	    (P_R_opt[t, r]/Sbase + ΔP_R_up[t, r] - ΔP_R_dn[t, r]) <=
			renewables.generation[r][t]/Sbase);

	# Ramp-up limit
	@constraint(CM_mod, RampUp[g = G, t = T; t > T[1]],
		(P_opt[t, g]/Sbase + ΔP_up[t, g] - ΔP_dn[t, g]) -
			(P_opt[t-1, g]/Sbase + ΔP_up[t-1, g] - ΔP_dn[t-1, g]) <=
			powerplants.rup[g]/Sbase)

	# Ramp-down limit
	@constraint(CM_mod, RampDown[g = G, t = T; t > T[1]],
		-((P_opt[t, g]/Sbase + ΔP_up[t, g] - ΔP_dn[t, g]) -
			(P_opt[t-1, g]/Sbase + ΔP_up[t-1, g] - ΔP_dn[t-1, g])) <=
			powerplants.rdn[g]/Sbase)

	### DC power flow constraints
	# Power injection balance
	@constraint(CM_mod, PowerInjectionBal[j = J, t = T],
		sum((P_opt[t, g]/Sbase + ΔP_up[t, g] - ΔP_dn[t, g])
			for g in getKeyVector(powerplants.node, j)) +
		sum((P_R_opt[t, r]/Sbase + ΔP_R_up[t, r] - ΔP_R_dn[t, r])
			for r in getKeyVector(renewables.node, j)) -
				nodes.load[j][t]/Sbase == P_inj[t, j]);

	# Power injection angle
	@constraint(CM_mod, PowerInjectionAng[j = J, t = T],
		sum(B_prime[j, k] * (Θ[t, j] - Θ[t, k]) for k in K)
			== P_inj[t, j]);

	@constraint(CM_mod, LinePowerFlow[k = K, j = J, t = T; j != k],
		B_prime[j, k] * (Θ[t, j] - Θ[t, k]) == P_flow[t, j, k]);

	@constraint(CM_mod, LinePowerFlowMax[k = K, j = J, t = T],
		P_flow[t, j, k] <= lines_pmax[j, k]/Sbase);

	@constraint(CM_mod, LinePowerFlowMin[k = K, j = J, t = T],
		P_flow[t, j, k] >= -lines_pmax[j, k]/Sbase);

	# Objective function
	@objective(CM_mod, Min,
	    sum(powerplants.mc[g][1] * (ΔP_up[t, g]) * Sbase +
			(price[t] - powerplants.mc[g][1]) * ΔP_dn[t, g] *
				Sbase for g in G, t in T) +
		sum(renewables.mc[r] * (ΔP_R_up[t, r]) * Sbase +
			(price[t] - renewables.mc[r]) * ΔP_R_dn[t, r] *
				Sbase for r in R, t in T));

	# Initiate optimisation process
	JuMP.optimize!(CM_mod)

	# Export results
	ΔP_up_opt = JuMP.value.(ΔP_up) * Sbase
	ΔP_dn_opt = JuMP.value.(ΔP_dn) * Sbase
	ΔP_R_up_opt = JuMP.value.(ΔP_R_up) * Sbase
	ΔP_R_dn_opt = JuMP.value.(ΔP_R_dn) * Sbase
	Θ_opt = (JuMP.value.(Θ)) * 360/(2π)
	P_flow_opt = JuMP.value.(P_flow)*Sbase
	P_inj_opt = JuMP.value.(P_inj)*Sbase
	price = JuMP.dual.(MarketClearing)

	return(CM_mod,
	       ΔP_up_opt,
		   ΔP_dn_opt,
		   ΔP_R_up_opt,
		   ΔP_R_dn_opt,
	       Θ_opt,
	       P_inj_opt,
	       P_flow_opt,
		   price
	       )
end
