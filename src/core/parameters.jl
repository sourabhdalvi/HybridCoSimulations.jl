function _set_parameter!(
    array::AbstractArray{Float64},
    ::JuMP.Model,
    value::Vector{Float64},
    ixs::Tuple,
)
    array[ixs...] = value[ixs[2]]
    return
end

function _set_parameter!(
    array::AbstractArray{PJ.ParameterRef},
    model::JuMP.Model,
    value::Vector{Float64},
    ixs::Tuple,
)
    array[ixs...] = PSI.add_jump_parameter(model, value[ixs[2]])
    return
end

function PSI.set_parameter!(
    container::PSI.ParameterContainer,
    jump_model::JuMP.Model,
    parameter::Vector{Float64},
    multiplier::Float64,
    ixs...,
)
    PSI.get_multiplier_array(container)[ixs...] = multiplier
    param_array = PSI.get_parameter_array(container)
    _set_parameter!(param_array, jump_model, parameter, ixs)
    return
end

struct MaximumEnergyParameter <: PSI.TimeSeriesParameter end
struct MinimumEnergyParameter <: PSI.TimeSeriesParameter end
struct TotalEnergyParameter <: PSI.TimeSeriesParameter end
struct ProductionLowerBoundParameter <: PSI.TimeSeriesParameter end
struct ThetaLowerBoundParameter <: PSI.TimeSeriesParameter end
struct PowerScheduledParameter <: PSI.VariableValueParameter end
struct CalculatedCostParameter <: PSI.TimeSeriesParameter end

struct ConstraintValueAttributes{T <: PSI.OptimizationContainerKey} <: PSI.ParameterAttributes
    attribute_key::T
end

get_attribute_key(attr::ConstraintValueAttributes) = attr.attribute_key

abstract type ConstraintValueParameter <: PSI.RightHandSideParameter end
struct PowerPriceParameter <: ConstraintValueParameter end
