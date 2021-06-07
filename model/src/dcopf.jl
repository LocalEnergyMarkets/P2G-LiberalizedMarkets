### DCOPF without renewable energy sources
function DCOPF(time,
			   nodes::Nodes,
			   lines::Lines,
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

	# Initialise JuMP model: DCOPF
	DCOPF_mod = JuMP.Model(with_optimizer(Gurobi.Optimizer))

	# Variables
	@variable(DCOPF_mod, P[T, G] >= 0)
	@variable(DCOPF_mod, Θ[T, J])
	@variable(DCOPF_mod, P_inj[T, J])
	@variable(DCOPF_mod, P_flow[T, K, J])

	# Fix the voltage angle of the slack bus
	for t in T
		fix(Θ[t, slack], 0)
	end

	# Constraints
	# Market clearing/power balance
	@constraint(DCOPF_mod, MarketClearing[t = T],
	    sum(P[t, g] for g in G) == nodes.systemload[t]/Sbase);

	# Upper generation limit
	@constraint(DCOPF_mod, GenerationLimitUp[g = G, t = T],
	    P[t, g] <= powerplants.pmax[g]/Sbase);

	# Lower generation limit
	@constraint(DCOPF_mod, GenerationLimitDown[g = G, t = T],
	    P[t, g] >= powerplants.pmin[g]/Sbase);

	# Ramp-up limit
	@constraint(DCOPF_mod, RampUp[g = G, t = T; t > t[1]],
		(P[t, g]) - (P[t-1, g]) <= powerplants.rup[g])

	# Ramp-down limit
	@constraint(DCOPF_mod, RampDown[g = G, t = T; t > t[1]],
		-((P[t, g]) - (P[t-1, g])) <= powerplants.rdn[g])

	### DC power flow constraints
	# Power injection balance
	@constraint(DCOPF_mod, PowerInjectionBal[j = J, t = T],
		sum(P[t, g] for g in getKeyVector(powerplants.node, j)) -	# all generation units connected to a node
			nodes.load[j][t]/Sbase == P_inj[t, j]);

	# Power injection angle
	@constraint(DCOPF_mod, PowerInjectionAng[j = J, t = T],
		sum(B_prime[j, k] * (Θ[t, j] - Θ[t, k]) for k in K)
			== P_inj[t, j]);

	@constraint(DCOPF_mod, LinePowerFlow[k = K, j = J, t = T; j != k],
		B_prime[j, k] * (Θ[t, j] - Θ[t, k]) == P_flow[t, j, k]);

	@constraint(DCOPF_mod, LinePowerFlowMax[k = K, j = J, t = T],
		P_flow[t, j, k] <= lines_pmax[j, k]/Sbase);

	@constraint(DCOPF_mod, LinePowerFlowMin[k = K, j = J, t = T],
		P_flow[t, j, k] >= -lines_pmax[j, k]/Sbase);

	# Objective function
	@objective(DCOPF_mod, Min,
	    sum(powerplants.mc[g][1] * P[t, g] * Sbase for g in G, t in T));


	# Initiate optimisation process
	JuMP.optimize!(DCOPF_mod)

	# Export results
	P_opt = JuMP.value.(P)*Sbase
	Θ_opt = (JuMP.value.(Θ)) * 360/(2π)
	P_flow_opt = JuMP.value.(P_flow)*Sbase
	P_inj_opt = JuMP.value.(P_inj)*Sbase

	return(DCOPF_mod,
	       P_opt,
	       Θ_opt,
	       P_inj_opt,
	       P_flow_opt
	       )
end

### DCOPF with renewable energy sources
function DCOPF(time,
			   nodes::Nodes,
			   lines::Lines,
			   powerplants::PowerPlants,
			   renewables::Renewables
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

	# Initialise JuMP model: DCOPF
	DCOPF_mod = JuMP.Model(with_optimizer(Gurobi.Optimizer))

	# Variables
	@variable(DCOPF_mod, P[T, G] >= 0)
	@variable(DCOPF_mod, P_R[T, R] >= 0)
	@variable(DCOPF_mod, Θ[T, J])
	@variable(DCOPF_mod, P_inj[T, J])
	@variable(DCOPF_mod, P_flow[T, K, J])

	# Fix the voltage angle of the slack bus
	for t in T
		fix(Θ[t, slack], 0)
	end

	# Constraints
	# Market clearing/power balance
	@constraint(DCOPF_mod, MarketClearing[t = T],
	    sum(P[t, g] for g in G) +
			sum(P_R[t, r] for r in R) == nodes.systemload[t]/Sbase);

	# Upper generation limit
	@constraint(DCOPF_mod, GenerationLimitUp[g = G, t = T],
	    P[t, g] <= powerplants.pmax[g]/Sbase);

	# Lower generation limit
	@constraint(DCOPF_mod, GenerationLimitDown[g = G, t = T],
	    P[t, g] >= powerplants.pmin[g]/Sbase);

	# Upper generation limit for renewables
	@constraint(DCOPF_mod, ResGenerationLimitUp[r = R, t = T],
	    P_R[t, r] <= renewables.generation[r][t]/Sbase);

	# Ramp-up limit
	@constraint(DCOPF_mod, RampUp[g = G, t = T; t > t[1]],
		(P[t, g]) - (P[t-1, g]) <= powerplants.rup[g])

	# Ramp-down limit
	@constraint(DCOPF_mod, RampDown[g = G, t = T; t > t[1]],
		-((P[t, g]) - (P[t-1, g])) <= powerplants.rdn[g])

	### DC power flow constraints
	# Power injection balance
	@constraint(DCOPF_mod, PowerInjectionBal[j = J, t = T],
		sum(P[t, g] for g in getKeyVector(powerplants.node, j)) +
			sum(P_R[t, r] for r in getKeyVector(renewables.node, j)) -
				nodes.load[j][t]/Sbase == P_inj[t, j]);

	# Power injection angle
	@constraint(DCOPF_mod, PowerInjectionAng[j = J, t = T],
		sum(B_prime[j, k] * (Θ[t, j] - Θ[t, k]) for k in K)
			== P_inj[t, j]);

	@constraint(DCOPF_mod, LinePowerFlow[k = K, j = J, t = T; j != k],
		B_prime[j, k] * (Θ[t, j] - Θ[t, k]) == P_flow[t, j, k]);

	@constraint(DCOPF_mod, LinePowerFlowMax[k = K, j = J, t = T],
		P_flow[t, j, k] <= lines_pmax[j, k]/Sbase);

	@constraint(DCOPF_mod, LinePowerFlowMin[k = K, j = J, t = T],
		P_flow[t, j, k] >= -lines_pmax[j, k]/Sbase);

	# Objective function
	@objective(DCOPF_mod, Min,
	    sum(powerplants.mc[g][1] * P[t, g] * Sbase for g in G, t in T) +
			sum(renewables.mc[r] * P_R[t, r] * Sbase for r in R, t in T));

	# Initiate optimisation process
	JuMP.optimize!(DCOPF_mod)

	# Export results
	P_opt = JuMP.value.(P)*Sbase
	P_R_opt = JuMP.value.(P_R)*Sbase
	Θ_opt = (JuMP.value.(Θ)) * 360/(2π)
	P_flow_opt = JuMP.value.(P_flow)*Sbase
	P_inj_opt = JuMP.value.(P_inj)*Sbase

	return(DCOPF_mod,
	       P_opt,
		   P_R_opt,
	       Θ_opt,
	       P_inj_opt,
	       P_flow_opt
	       )
end
