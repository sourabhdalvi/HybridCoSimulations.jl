
struct VariableUpperBoundConstraint <: PSI.ConstraintType end
struct VariableLowerBoundConstraint <: PSI.ConstraintType end
struct TotalProductionLimitConstraint <: PSI.ConstraintType end
struct ResidualEnergyBoundConstraint <: PSI.ConstraintType end
struct EnergyInitialConditionConstraint <: PSI.ConstraintType end
abstract type SingleTimeDimensionConstraint <: PSI.ConstraintType end
struct EnergyAboveInitialTimeConstraint <: SingleTimeDimensionConstraint end
struct EnergySlackVariableK1TimeConstraint <: SingleTimeDimensionConstraint end
struct EnergySlackVariableK2TimeConstraint <: SingleTimeDimensionConstraint end
