
struct HybridCostOpProblem <: PSI.DecisionProblem end

function get_sorted_keys(keys::Base.KeySet)
    sorted_keys = sort!(collect((get_priority(k),k) for k in keys), by = x-> x[1], )
    return sorted_keys
end

get_priority(::PSI.ParameterKey{<:PSI.ParameterType,<:PSY.Component}) = 0
get_priority(::PSI.ParameterKey{PowerScheduledParameter, PSY.HybridSystem}) = 1
get_priority(::PSI.ParameterKey{PSI.CostFunctionParameter, PSY.HybridSystem}) = 2
get_priority(::PSI.ParameterKey{CalculatedCostParameter, PSY.HybridSystem}) = 3

function PSI.update_parameters!(
    model::PSI.DecisionModel{HybridCostOpProblem},
    decision_states::PSI.DatasetContainer{PSI.DataFrameDataset},
)
    sorted_keys = get_sorted_keys(keys(PSI.get_parameters(model)))
    for (priority, key) in sorted_keys
        PSI.update_parameter_values!(model, key, decision_states)
    end
    if !PSI.is_synchronized(model)
        PSI.update_objective_function!(PSI.get_optimization_container(model))
        obj_func = PSI.get_objective_function(PSI.get_optimization_container(model))
        PSI.set_synchronized_status(obj_func, true)
    end
    return
end
