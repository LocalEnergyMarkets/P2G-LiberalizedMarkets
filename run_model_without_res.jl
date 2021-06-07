### Without renewables for validation of IEEE test cases
###################
# Run DCOPF #######
###################

DCOPF_mod, P_opt, Θ_opt, P_inj_opt, P_flow_opt =
	DCOPF(time, nodes, lines, pp)

# Optimisation status
JuMP.termination_status(DCOPF_mod)
JuMP.primal_status(DCOPF_mod)
JuMP.dual_status(DCOPF_mod)

# Results
JuMP.objective_value(DCOPF_mod)
P_opt
Θ_opt
P_inj_opt
P_flow_opt

###################
# Run ED ##########
###################

ED_mod, P_opt, price = EconomicDispatch(time, nodes, pp)

# Optimisation status
JuMP.termination_status(ED_mod)
JuMP.primal_status(ED_mod)
JuMP.dual_status(ED_mod)

# Results
JuMP.objective_value(ED_mod)
P_opt
price

# Dispatch: Unit commitment and power generation
output_EconomicDispatch = DataFrame(time=Int64[],unit=Int64[],output=Float64[])
for t in time
	for g in pp.unit
		val = P_opt[t, g]
		push!(output_EconomicDispatch, [t g val])
	end
end

CSV.write("output/EconomicDispatch.csv", output_EconomicDispatch)
electrondisplay(output_EconomicDispatch)
electrondisplay(powerplants_df)

###################
# Run CM ##########
###################

CM_mod, ΔP_up_opt, ΔP_dn_opt, Θ_opt, P_inj_opt, P_flow_opt =
	CongestionManagement(time, nodes, lines, price, P_opt, pp)

# Optimisation status
JuMP.termination_status(CM_mod)
JuMP.primal_status(CM_mod)
JuMP.dual_status(CM_mod)

# Results
JuMP.objective_value(CM_mod)
ΔP_up_opt
ΔP_dn_opt
Θ_opt
P_inj_opt
P_flow_opt

# Testing
P_opt.data .+ ΔP_up_opt.data .- ΔP_dn_opt.data
P_opt.data
