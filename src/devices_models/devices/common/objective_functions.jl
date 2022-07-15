function add_slack_k1_cost!(
    container::PSI.OptimizationContainer,
    ::U,
    devices::PSI.IS.FlattenIteratorWrapper{T},
    ::V,
) where {T <: PSY.Component, U <: PSI.VariableType, V <: PSI.AbstractDeviceFormulation}
    multiplier = PSI.objective_function_multiplier(U(), V())
    time_steps = PSI.get_time_steps(container)
    for d in devices
        op_cost_data = PSY.get_operation_cost(d)
        cost_term = 0.0 #TODO: cost for slack k1
        iszero(cost_term) && continue
        _add_proportional_term!(container, U(), d, 1, cost_term * multiplier)
    end
    return
end

function add_slack_k2_cost!(
    container::PSI.OptimizationContainer,
    ::U,
    devices::PSI.IS.FlattenIteratorWrapper{T},
    ::V,
) where {T <: PSY.Component, U <: PSI.VariableType, V <: PSI.AbstractDeviceFormulation}
    multiplier = PSI.objective_function_multiplier(U(), V())
    time_steps = PSI.get_time_steps(container)
    for d in devices
        op_cost_data = PSY.get_operation_cost(d)
        cost_term = 0.0 #TODO: cost for slack k2
        iszero(cost_term) && continue
        _add_proportional_term!(container, U(), d, 1, cost_term * multiplier)
    end
    return
end

function add_curtailment_cost!(
    container::PSI.OptimizationContainer,
    ::U,
    devices::PSI.IS.FlattenIteratorWrapper{T},
    ::V,
) where {T <: PSY.Component, U <: PSI.VariableType, V <: PSI.AbstractDeviceFormulation}
    multiplier = PSI.objective_function_multiplier(U(), V())
    time_steps = PSI.get_time_steps(container)
    for d in devices
        op_cost_data = PSY.get_operation_cost(d)
        cost_term = 40.0
        iszero(cost_term) && continue
        for t in time_steps
            _add_proportional_term!(container, U(), d, t, cost_term * multiplier)
        end
    end
    return
end

function PSI._add_proportional_term!(
    container::PSI.OptimizationContainer,
    ::T,
    component::U,
    t::Int,
    linear_term::Float64,
) where {T <: PSI.VariableType, U <: PSY.Component}
    component_name = PSY.get_name(component)
    @debug "Linear Variable Cost" _group = PSI.LOG_GROUP_COST_FUNCTIONS component_name
    variable = PSI.get_variable(container, T(), U)[component_name, t]
    lin_cost = variable * linear_term
    PSI.add_to_objective_invariant_expression!(container, lin_cost)
    return lin_cost
end

function PSI._add_pwl_term!(
    container::PSI.OptimizationContainer,
    component::T,
    cost_data::Matrix{PSY.VariableCost{Vector{Tuple{Float64, Float64}}}},
    ::U,
    ::V,
) where {T <: PSY.HybridSystem, U <: PSI.VariableType, V <: HybridProbablisticCostDispatch}
    multiplier = PSI.objective_function_multiplier(U(), V())
    resolution = PSI.get_resolution(container)
    dt = Dates.value(Dates.Second(resolution)) / PSI.SECONDS_IN_HOUR
    base_power = PSI.get_base_power(container)
    # Re-scale breakpoints by Basepower
    name = PSY.get_name(component)
    time_steps = PSI.get_time_steps(container)
    pwl_cost_expressions = Vector{JuMP.AffExpr}(undef, time_steps[end])
    sos_val = PSI._get_sos_value(container, V, component)
    for t in time_steps
        data = PSY.get_cost(cost_data[t])
        # is_power_data_compact = PSI._check_pwl_compact_data(component, data, base_power)
        # if !PSI.uses_compact_power(component, V()) && is_power_data_compact
        #     error(
        #         "The data provided is not compatible with formulation $V. Use a formulation compatible with Compact Cost Functions",
        #     )
        #     # data = _convert_to_full_variable_cost(data, component)
        # elseif PSI.uses_compact_power(component, V()) && !is_power_data_compact
        #     data = PSI._convert_to_compact_variable_cost(data)
        # else
        #     @debug PSI.uses_compact_power(component, V()) name T V
        #     @debug is_power_data_compact name T V
        # end
        slopes = PSY.get_slopes(data)
        # First element of the return is the average cost at P_min.
        # Shouldn't be passed for convexity check
        is_convex = PSI._slope_convexity_check(slopes[2:end])
        break_points = map(x -> last(x), data) ./ base_power
        PSI._add_pwl_variables!(container, T, name, t, data)
        PSI._add_pwl_constraint!(container, component, U(), break_points, sos_val, t)
        if !is_convex
            # PSI._add_pwl_sos_constraint!(container, component, U(), break_points, sos_val, t)
        end
        pwl_cost = PSI._get_pwl_cost_expression(container, component, t, data, multiplier * dt)
        pwl_cost_expressions[t] = pwl_cost
    end
    return pwl_cost_expressions
end
