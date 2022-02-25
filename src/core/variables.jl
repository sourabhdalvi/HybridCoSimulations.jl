
struct CurtailedEnergy <: PSI.VariableType end
struct EnergyAboveInitial <: PSI.VariableType end
struct EnergySlackVariableK1 <: PSI.VariableType end
struct EnergySlackVariableK2 <: PSI.VariableType end

PSI.convert_result_to_natural_units(::Type{CurtailedEnergy}) = true
PSI.convert_result_to_natural_units(::Type{EnergyAboveInitial}) = true
