module HybridCoSimulations

#################################################################################
# Exports

export VariableUpperBoundConstraint
export VariableLowerBoundConstraint
export TotalProductionLimitConstraint
export ResidualEnergyBoundConstraint
export EnergyInitialConditionConstraint

export ProductionUpperBoundExpression
export TotalProductionExpression
export ProductionLowerBoundExpression

export CurtailedEnergy
export EnergyAboveInitial
export EnergySlackVariableK1
export EnergySlackVariableK2

export HybridProbablisticDispatch

#################################################################################
# Imports

# Modeling Imports
import JuMP
# so that users do not need to import JuMP to use a solver with PowerModels
import JuMP.Containers: DenseAxisArray, SparseAxisArray
import ParameterJuMP
import PowerSystems
import PowerSimulations
import InfrastructureSystems
import InfrastructureSystems: @assert_op, list_recorder_events, get_name
import PowerModels

# Base Imports
import Base.getindex
import Base.length
import Base.first

# TimeStamp Management Imports
import Dates
import TimeSeries


################################################################################

# Type Alias From other Packages
const PSY = PowerSystems
const PSI = PowerSimulations
const IS = InfrastructureSystems
const PJ = ParameterJuMP
const TS = TimeSeries
const PM = PowerModels
#################################################################################
# Includes
include("core/definitions.jl")

include("core/variables.jl")
include("core/constraints.jl")
include("core/expressions.jl")
include("core/parameters.jl")
include("core/parameters.jl")


include("devices_models/devices/common/add_variable.jl")
include("devices_models/devices/common/add_to_expression.jl")
include("devices_models/devices/hybrid_generation.jl")

include("devices_models/device_constructors/hybridgeneration_constructor.jl")

include("utils/jump_utils.jl")

end # module

