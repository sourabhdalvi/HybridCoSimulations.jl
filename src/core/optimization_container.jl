function PSI.add_aux_variable_container!(
    container::PSI.OptimizationContainer,
    ::T,
    ::Type{U},
    axs...;
    sparse=false,
) where {T <: CostBidAuxVariable, U <: PSY.Component}
    var_key = PSI.AuxVarKey(T, U)
    if sparse
        aux_variable_container = PSI.sparse_container_spec(Vector{Tuple{Float64, Float64}}, axs...)
    else
        aux_variable_container = PSI.container_spec(Vector{Tuple{Float64, Float64}}, axs...)
    end
    PSI._assign_container!(container.aux_variables, var_key, aux_variable_container)
    return aux_variable_container
end


# function _add_param_container!(
#     container::OptimizationContainer,
#     key::ParameterKey{T, U},
#     attribute::VariableValueAttributes{<:OptimizationContainerKey},
#     axs...;
#     sparse=false,
# ) where {T <: VariableValueParameter, U <: PSY.Component}
#     # Temporary while we change to POI vs PJ
#     param_type = built_for_recurrent_solves(container) ? PJ.ParameterRef : Float64
#     if sparse
#         param_array = sparse_container_spec(param_type, axs...)
#         multiplier_array = sparse_container_spec(Float64, axs...)
#     else
#         param_array = DenseAxisArray{param_type}(undef, axs...)
#         multiplier_array = fill!(DenseAxisArray{Float64}(undef, axs...), NaN)
#     end
#     param_container = ParameterContainer(attribute, param_array, multiplier_array)
#     _assign_container!(container.parameters, key, param_container)
#     return param_container
# end
