# Export
season = ""
param = "gas_26,45"
session_time = Dates.now()
session = Dates.format(session_time, "yyyy-mm-dd__HH-MM-SS")

# Create session folder for output
mkdir("output/" * session)

# ##########
# # CM info
# output_CM_info = DataFrame(parameter=String[],value=Float64[])
# push!(output_CM_info, ["Total system costs" JuMP.objective_value(CM_mod)])
# push!(output_CM_info, ["P_up" sum(CM_ΔP_up_opt)])
# push!(output_CM_info, ["P_dn" sum(CM_ΔP_dn_opt)])
# push!(output_CM_info, ["P_R_up" sum(CM_ΔP_R_up_opt)])
# push!(output_CM_info, ["P_R_dn" sum(CM_ΔP_R_dn_opt)])
#
# electrondisplay(output_CM_info)
# CSV.write("output/CM_info_" * season * param * ".csv", output_CM_info)
#
# # CM PtG info
# output_CM_PtG_info = DataFrame(parameter=String[],value=Float64[])
# push!(output_CM_PtG_info, ["Total system costs" JuMP.objective_value(CM_PtG_mod)])
# push!(output_CM_PtG_info, ["P_up" sum(CM_PtG_ΔP_up_opt)])
# push!(output_CM_PtG_info, ["P_dn" sum(CM_PtG_ΔP_dn_opt)])
# push!(output_CM_PtG_info, ["P_R_up" sum(CM_PtG_ΔP_R_up_opt)])
# push!(output_CM_PtG_info, ["P_R_dn" sum(CM_PtG_ΔP_R_dn_opt)])
# push!(output_CM_PtG_info, ["P_syn" sum(CM_PtG_P_syn_opt)])
# push!(output_CM_PtG_info, ["D_PtG" sum(CM_PtG_D_PtG_opt)])
# push!(output_CM_PtG_info, ["L_syn" sum(CM_PtG_L_syn_opt)])
#
# electrondisplay(output_CM_PtG_info)
# CSV.write("output/CM_PtG_info_" * season * param *".csv", output_CM_PtG_info)

function has(x, y)
	x == y
end

function getKeyVector(df::Dict, value)
	key_value = [k for (k,v) in df if has(v, value)]
	return key_value
end


###################
# ED ##############
###################

# Dispatchable power plants
output_ED_P_opt = DataFrame(time=Int64[],unit=Int64[],fuel=String[],output=Float64[])
for t in time
	for g in pp.unit
		val = ED_P_opt[t, g]
		fuel =  pp.fuel[g]
		push!(output_ED_P_opt, [t g fuel val])
	end
end
CSV.write("output/" * session * "/" * "ED_P.csv", output_ED_P_opt)

# RES generation
output_ED_P_R_opt = DataFrame(time=Int64[],unit=Int64[],fuel=String[],output=Float64[])
for t in time
	for r in res.unit
		val = ED_P_R_opt[t, r]
		tech =  res.fuel[r]
		push!(output_ED_P_R_opt, [t r tech val])
	end
end
CSV.write("output/" * session * "/" * "ED_P_R.csv", output_ED_P_R_opt)

# Maximum available RES infeed from input data
output_MaxRES = DataFrame(time=Int64[],unit=Int64[],fuel=String[],output=Float64[],capacity=Float64[])
for t in time
	for r in res.unit
		output = res.generation[r][t]
		capacity = res.pmax[r]
		tech =  res.fuel[r]
		push!(output_MaxRES, [t r tech output capacity])
	end
end
CSV.write("output/" * session * "/" * "MaxRES.csv", output_MaxRES)

# Load
output_load = DataFrame(time=Int64[],load=Float64[])
for t in time
	load = nodes.systemload[t]
	push!(output_load, [t load])
end
CSV.write("output/" * session * "/" * "load.csv", output_load)

# Prices
output_ED_price = DataFrame(time=Int64[],price=Float64[])
for t in time
	price =  ED_price[t]
	push!(output_ED_price, [t price])
end
CSV.write("output/" * session * "/" * "ED_price.csv", output_ED_price)

# Must-run
output_pmin = DataFrame(time=Int64[],unit=Int64[],fuel=String[],output=Float64[])
for t in time
	for g in pp.unit
		val = pp.pmin[g]
		fuel =  pp.fuel[g]
		push!(output_pmin, [t g fuel val])
	end
end
CSV.write("output/" * session * "/" * "pmin.csv", output_pmin)

###################
# CM ##############
###################

# Dispatchable power plants
output_CM_ΔP_up_opt = DataFrame(time=Int64[],unit=Int64[],fuel=String[],output=Float64[])
for t in time
	for g in pp.unit
		val = CM_ΔP_up_opt[t, g]
		fuel =  pp.fuel[g]
		push!(output_CM_ΔP_up_opt, [t g fuel val])
	end
end
CSV.write("output/" * session * "/" * "CM_P_up.csv", output_CM_ΔP_up_opt)

output_CM_ΔP_dn_opt = DataFrame(time=Int64[],unit=Int64[],fuel=String[],output=Float64[])
for t in time
	for g in pp.unit
		val = -1*CM_ΔP_dn_opt[t, g]
		fuel =  pp.fuel[g]
		push!(output_CM_ΔP_dn_opt, [t g fuel val])
	end
end
CSV.write("output/" * session * "/" * "CM_P_dn.csv", output_CM_ΔP_dn_opt)

# RES generation
output_CM_ΔP_R_up_opt = DataFrame(time=Int64[],unit=Int64[],fuel=String[],output=Float64[])
for t in time
	for r in res.unit
		val = CM_ΔP_R_up_opt[t, r]
		tech =  res.fuel[r]
		push!(output_CM_ΔP_R_up_opt, [t r tech val])
	end
end
CSV.write("output/" * session * "/" * "CM_P_R_up.csv", output_CM_ΔP_R_up_opt)

output_CM_ΔP_R_dn_opt = DataFrame(time=Int64[],unit=Int64[],fuel=String[],output=Float64[])
for t in time
	for r in res.unit
		val = -1*CM_ΔP_R_dn_opt[t, r]
		tech =  res.fuel[r]
		push!(output_CM_ΔP_R_dn_opt, [t r tech val])
	end
end
CSV.write("output/" * session * "/" * "CM_P_R_dn.csv", output_CM_ΔP_R_dn_opt)

###################
# CM PtG ##########
###################

# Dispatchable power plants
output_CM_PtG_ΔP_up_opt = DataFrame(time=Int64[],unit=Int64[],fuel=String[],output=Float64[])
for t in time
	for g in pp.unit
		val = CM_PtG_ΔP_up_opt[t, g]
		fuel =  pp.fuel[g]
		push!(output_CM_PtG_ΔP_up_opt, [t g fuel val])
	end
end
CSV.write("output/" * session * "/" * "CM_PtG_P_up.csv", output_CM_PtG_ΔP_up_opt)

output_CM_PtG_ΔP_dn_opt = DataFrame(time=Int64[],unit=Int64[],fuel=String[],output=Float64[])
for t in time
	for g in pp.unit
		val = -1*CM_PtG_ΔP_dn_opt[t, g]
		fuel =  pp.fuel[g]
		push!(output_CM_PtG_ΔP_dn_opt, [t g fuel val])
	end
end
CSV.write("output/" * session * "/" * "CM_PtG_P_dn.csv", output_CM_PtG_ΔP_dn_opt)

# RES generation
output_CM_PtG_ΔP_R_up_opt = DataFrame(time=Int64[],unit=Int64[],fuel=String[],output=Float64[])
for t in time
	for r in res.unit
		val = CM_PtG_ΔP_R_up_opt[t, r]
		tech =  res.fuel[r]
		push!(output_CM_PtG_ΔP_R_up_opt, [t r tech val])
	end
end
CSV.write("output/" * session * "/" * "CM_PtG_P_R_up.csv", output_CM_PtG_ΔP_R_up_opt)

output_CM_PtG_ΔP_R_dn_opt = DataFrame(time=Int64[],unit=Int64[],fuel=String[],output=Float64[])
for t in time
	for r in res.unit
		val = -1*CM_PtG_ΔP_R_dn_opt[t, r]
		tech =  res.fuel[r]
		push!(output_CM_PtG_ΔP_R_dn_opt, [t r tech val])
	end
end
CSV.write("output/" * session * "/" * "CM_PtG_P_R_dn.csv", output_CM_PtG_ΔP_R_dn_opt)

# Electricity demand from PtG units
output_CM_PtG_D_PtG_opt = DataFrame(time=Int64[],unit=Int64[],fuel=String[],output=Float64[])
for t in time
	for r in res.unit
		val = CM_PtG_D_PtG_opt[t, r]
		fuel = "PtG"
		push!(output_CM_PtG_D_PtG_opt, [t r fuel val])
	end
end
CSV.write("output/" * session * "/" * "CM_PtG_D_PtG.csv", output_CM_PtG_D_PtG_opt)

# Electricity generation from synthetic methane
output_CM_PtG_P_syn_opt = DataFrame(time=Int64[],unit=Int64[],fuel=String[],output=Float64[])
for t in time
	for e in getKeyVector(pp.fuel, "NaturalGas")
		val = CM_PtG_P_syn_opt[t, e]
		fuel = "SNG"
		push!(output_CM_PtG_P_syn_opt, [t e fuel val])
	end
end
CSV.write("output/" * session * "/" * "CM_PtG_P_syn.csv", output_CM_PtG_P_syn_opt)

# Synthetic methane storage level
output_CM_PtG_L_syn_opt = DataFrame(time=Int64[],storage=Float64[])
for t in time
	storage = CM_PtG_L_syn_opt[t]
	push!(output_CM_PtG_L_syn_opt, [t storage])
end
CSV.write("output/" * session * "/" * "CM_PtG_L_syn.csv", output_CM_PtG_L_syn_opt)

# System costs
output_system_cost = DataFrame(model=String[],system_cost=Float64[])
push!(output_system_cost, ["DCOPF" JuMP.objective_value(DCOPF_mod)])
push!(output_system_cost, ["Economic Dispatch" JuMP.objective_value(ED_mod)])
push!(output_system_cost, ["Congestion Management" JuMP.objective_value(CM_mod)])
push!(output_system_cost, ["Congestion Management (PtG)" JuMP.objective_value(CM_PtG_mod)])
CSV.write("output/" * session * "/" * "system_cost.csv", output_system_cost)

# ### Electron display
# electrondisplay(output_system_cost)
#
# # ED
# electrondisplay(output_ED_P_opt)
# electrondisplay(output_ED_P_R_opt)
# electrondisplay(output_MaxRES)
# electrondisplay(output_load)
# electrondisplay(output_ED_price)
#
# # CM
# electrondisplay(output_CM_ΔP_up_opt)
# electrondisplay(output_CM_ΔP_dn_opt)
# electrondisplay(output_CM_ΔP_R_up_opt)
# electrondisplay(output_CM_ΔP_R_dn_opt)
#
# # CM + PtG
# electrondisplay(output_CM_PtG_ΔP_up_opt)
# electrondisplay(output_CM_PtG_ΔP_dn_opt)
# electrondisplay(output_CM_PtG_ΔP_R_up_opt)
# electrondisplay(output_CM_PtG_ΔP_R_dn_opt)
# electrondisplay(output_CM_PtG_D_PtG_opt)
# electrondisplay(output_CM_PtG_P_syn_opt)
# electrondisplay(output_CM_PtG_L_syn_opt)
