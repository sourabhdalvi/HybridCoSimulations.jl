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
export HybridProbablisticCostDispatch

export HybridCostOpProblem
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
import DataFrames

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
include("core/auxiliary_variables.jl")
include("core/optimization_container.jl")

include("operation/decision_model.jl")

include("devices_models/devices/common/add_variable.jl")
include("devices_models/devices/common/add_to_expression.jl")
include("devices_models/devices/hybrid_generation.jl")
include("devices_models/devices/common/objective_functions.jl")

include("devices_models/device_constructors/hybridgeneration_constructor.jl")
include("parameters/add_parameters.jl")
include("parameters/update_parameters.jl")
include("simulation/initial_condition_update_simulation.jl")
include("utils/jump_utils.jl")

end # module

