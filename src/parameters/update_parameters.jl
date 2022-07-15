function _set_param_value!(
    param::DenseAxisArray,
    value::Vector{Float64},
    name::String,
    scen_id::Int,
    t::Int,
)
    JuMP.set_value(param[name, scen_id, t], value[scen_id])
    return
end

function _set_param_value!(
    param::DenseAxisArray,
    value::Float64,
    name::String,
    scen_id::Int,
    t::Int,
)
    JuMP.set_value(param[name, scen_id, t], value)
    return
end

function PSI.update_parameter_values!(
    model::PSI.OperationModel,
    key::PSI.ParameterKey{T, U},
    input::PSI.DatasetContainer{PSI.DataFrameDataset},
) where {T <: ProductionLowerBoundParameter, U <: PSY.HybridSystem}
    # Enable again for detailed debugging
    # TimerOutputs.@timeit RUN_SIMULATION_TIMER "$T $U Parameter Update" begin
    optimization_container = PSI.get_optimization_container(model)
    # Note: Do not instantite a new key here because it might not match the param keys in the container
    # if the keys have strings in the meta fields

    parameter_array = PSI.get_parameter_array(optimization_container, key)
    parameter_attributes = PSI.get_parameter_attributes(optimization_container, key)
    initial_forecast_time = PSI.get_current_time(model) # Function not well defined for DecisionModels
    horizon = PSI.get_time_steps(PSI.get_optimization_container(model))[end]
    components = PSI.get_available_components(U, PSI.get_system(model))
    V = PSI.get_time_series_type(parameter_attributes)
    no_of_scenarios = get_no_of_scenarios(components)
    for component in components
        name = PSY.get_name(component)
        ts_vector = PSI.get_time_series_values!(
            V,
            model,
            component,
            PSI.get_time_series_name(parameter_attributes),
            PSI.get_time_series_multiplier_id(parameter_attributes),
            initial_forecast_time,
            horizon,
        )
        for (t, value) in enumerate(ts_vector), scen_id in 1:no_of_scenarios
            _set_param_value!(parameter_array, value, name, scen_id, t)
        end
    end
    PSI.IS.@record :execution PSI.ParameterUpdateEvent(
        T,
        U,
        parameter_attributes,
        PSI.get_current_timestamp(model),
        PSI.get_name(model),
    )
    return
end

function PSI.update_parameter_values!(
    model::PSI.OperationModel,
    key::PSI.ParameterKey{T, U},
    input::PSI.DatasetContainer{PSI.DataFrameDataset},
) where {T <: PSI.CostFunctionParameter, U <: PSY.HybridSystem}
    # Enable again for detailed debugging
    # TimerOutputs.@timeit RUN_SIMULATION_TIMER "$T $U Parameter Update" begin
    container = PSI.get_optimization_container(model)
    # Note: Do not instantite a new key here because it might not match the param keys in the container
    # if the keys have strings in the meta fields
    parameter_array = PSI.get_parameter_array(container, key)
    parameter_attributes = PSI.get_parameter_attributes(container, key)
    initial_forecast_time = PSI.get_current_time(model) # Function not well defined for DecisionModels
    time_steps = PSI.get_time_steps(container)
    horizon = time_steps[end]
    if PSI.is_synchronized(container)
        obj_func = PSI.get_objective_function(container)
        PSI.set_synchronized_status(obj_func, false)
        PSI.reset_variant_terms(obj_func)
    end
    constriant_key = _network_constraint_key(PSI.get_network_model(PSI.get_template(model)))
    components = PSI.get_available_components(U, PSI.get_system(model))
    date = PSI.get_current_timestamp(model)
    s_index = PSI.find_timestamp_index(input.duals[constriant_key].timestamps, date)
    day_ahead_price = Float64[]
    base_power = PSI.get_base_power(container)
    (max_state_index, _) = size(input.duals[constriant_key].values)
    for t in time_steps.+(s_index-1)
        t = min(max_state_index, t)
        push!(day_ahead_price, (input.duals[constriant_key].values[t, "CopperPlateBalanceConstraint__System"]))
    end
    for component in components
        if PSI._has_variable_cost_parameter(component)
            name = PSY.get_name(component)
            variable_cost_forecast_values =_compute_cost_bids(container, component, day_ahead_price, s_index)
            for (t, value) in enumerate(variable_cost_forecast_values)
                if parameter_attributes.uses_compact_power
                    value, _ = PSI._convert_variable_cost(value)
                end
                PSI._set_param_value!(parameter_array, PSY.get_cost(value), name, t)
                PSI.update_variable_cost!(container, parameter_array, parameter_attributes, component, t)
                _update_pwl_variable_constraints!(container, component, value, PSI.ActivePowerVariable(), t)
            end
        end
    end
    IS.@record :execution PSI.ParameterUpdateEvent(
        T,
        U,
        parameter_attributes,
        PSI.get_current_timestamp(model),
        PSI.get_name(model),
    )

    return
end

function PSI.update_parameter_values!(
    model::PSI.OperationModel,
    key::PSI.ParameterKey{T, U},
    input::PSI.DatasetContainer{PSI.DataFrameDataset},
) where {T <: CalculatedCostParameter, U <: PSY.HybridSystem}

    container = PSI.get_optimization_container(model)
    # Note: Do not instantite a new key here because it might not match the param keys in the container
    # if the keys have strings in the meta fields
    parameter_array = PSI.get_parameter_array(container, key)
    parameter_attributes = PSI.get_parameter_attributes(container, key)

    initial_forecast_time = PSI.get_current_time(model) # Function not well defined for DecisionModels
    time_steps = PSI. get_time_steps(container)
    horizon = time_steps[end]
    cost_key = PSI.ParameterKey(PSI.CostFunctionParameter, U)
    cost_parameter_array = PSI.get_parameter_array(container, cost_key)
    components = PSI.get_available_components(U, PSI.get_system(model))
    for component in components, t in time_steps
        # if PSI._has_variable_cost_parameter(component)
            name = PSY.get_name(component)
            i = 1
            PSI.jump_value(cost_parameter_array[name, t])
            for cost_pairs in PSI.jump_value(cost_parameter_array[name, t])
                for c in cost_pairs
                    _set_param_value!(parameter_array, c, name, i, t)
                    i += 1
                end
            end
        # end
    end
    return
end

function _network_constraint_key(network_model::PSI.NetworkModel{PSI.CopperPlatePowerModel})
    return PSI.ConstraintKey(PSI.CopperPlateBalanceConstraint, PSY.System)
end

function _network_constraint_key(network_model::PSI.NetworkModel{PSI.DCPPowerModel})
    return PSI.ConstraintKey(PSI.NodalBalanceActiveConstraint, PSY.Bus)
end

function _network_constraint_key(network_model::PSI.NetworkModel{T}) where {T <: PSI.PM.AbstractPowerModel}
    error("Constriant key mapping not defined for $(T) network model.")
    return
end

function _compute_cost_bids(
    container::PSI.OptimizationContainer,
    component::T,
    day_ahead_price::Vector{Float64},
    period::Int,
) where {T <: PSY.HybridSystem, U <: PSI.VariableType,}

    time_steps = PSI.get_time_steps(container)
    resolution = PSI.get_resolution(container)
    fraction_of_hour = Dates.value(Dates.Minute(resolution)) / PSI.MINUTES_IN_HOUR
    name = PSY.get_name(component)
    p_variable = PSI.get_variable(container, PSI.ActivePowerVariable(), T)
    aux_variable_container = PSI.get_aux_variable(container, EnergyAuxVariable(), T)
    da_bid_param = PSI.get_parameter_array(container, PowerScheduledParameter(), T)
    da_multiplier = PSI.get_parameter_multiplier_array(container, PowerScheduledParameter(), T)
    initial_energy = filter(x -> x.component.name == name, PSI.get_initial_condition(container, InitialEnergyLevelHybrid(), T))[1]
    active_power_param = PSI.get_parameter_array(container, PSI.ActivePowerTimeSeriesParameter(), T)
    active_power_multiplier = PSI.get_parameter_multiplier_array(container, PSI.ActivePowerTimeSeriesParameter(), T)
    input_limit = PSY.get_input_active_power_limits(PSY.get_storage(component)).max
    hy_limit = PSY.get_interconnection_rating(component)
    output_limit = PSY.get_output_active_power_limits(PSY.get_storage(component)).max
    bat_cap = PSY.get_state_of_charge_limits(PSY.get_storage(component))
    eff = PSY.get_efficiency(PSY.get_storage(component))
    cost_data = Vector{Vector{Tuple{Float64, Float64}}}()
    for t in time_steps
        first_breakpoint = max(0, JuMP.value(active_power_param[name, t])
            - (min(eff.in * input_limit, (bat_cap.max - JuMP.value(PSI.get_value(initial_energy)))/fraction_of_hour)/eff.in)
            )
        second_breakpoint = min(JuMP.value(da_bid_param[name, t]), JuMP.value(active_power_param[name, t])
            + min(output_limit, eff.out * (JuMP.value(PSI.get_value(initial_energy)) - bat_cap.min)/fraction_of_hour)
            )
        third_breakpoint  = min(hy_limit, (JuMP.value(active_power_param[name, t]) 
            + min(output_limit, eff.out * (JuMP.value(PSI.get_value(initial_energy)) - bat_cap.min)/fraction_of_hour)))
        if first_breakpoint <= second_breakpoint && second_breakpoint <= third_breakpoint
            push!(cost_data, [( 0.0, first_breakpoint), (day_ahead_price[t], second_breakpoint), (1e6, third_breakpoint)])
        elseif second_breakpoint < first_breakpoint  && first_breakpoint < third_breakpoint
            push!(cost_data, [( 0.0, second_breakpoint), (day_ahead_price[t], first_breakpoint), (1e6, third_breakpoint)])
        elseif first_breakpoint < second_breakpoint && third_breakpoint < second_breakpoint
            push!(cost_data, [( 0.0, first_breakpoint), (day_ahead_price[t], third_breakpoint), (1e6, third_breakpoint)])
        end
    end
    cost_data = map(PSY.VariableCost, cost_data)
    return  cost_data
end

function _update_pwl_variable_constraints!(
    container::PSI.OptimizationContainer,
    component::T,
    cost_data::PSY.VariableCost{Vector{Tuple{Float64, Float64}}},
    ::U,
    time_period::Int,
) where {T <: PSY.HybridSystem, U <: PSI.VariableType,}

    variables = PSI.get_variable(container, U(), T)
    const_container = PSI.get_constraint(
        container,
        PSI.PieceWiseLinearCostConstraint(),
        T,
    )
    base_power = PSI.get_base_power(container)
    jump_model = PSI.get_jump_model(container)
    pwl_vars = PSI.get_variable(container, PSI.PieceWiseLinearCostVariable(), T)
    name = PSY.get_name(component)

    data = PSY.get_cost(cost_data)
    slopes = PSY.get_slopes(data)
    break_points = map(x -> last(x), data)
    len_cost_data = length(break_points)
    JuMP.delete(jump_model, const_container[name, time_period])
    const_container[name, time_period] = JuMP.@constraint(
        jump_model,
        variables[name, time_period] ==
        sum(pwl_vars[name, ix, time_period] * break_points[ix] for ix in 1:len_cost_data)
    )

    return
end

function PSI._update_pwl_cost_expression(
    container::PSI.OptimizationContainer,
    ::Type{T},
    component_name::String,
    time_period::Int,
    cost_data::Vector{NTuple{2, Float64}},
) where {T <: PSY.HybridSystem}
    pwl_var_container = PSI.get_variable(container, PSI.PieceWiseLinearCostVariable(), T)
    resolution = PSI.get_resolution(container)
    dt = Dates.value(Dates.Second(resolution)) / PSI.SECONDS_IN_HOUR
    gen_cost = JuMP.AffExpr(0.0)
    slopes = PSY.get_slopes(cost_data)
    upb = PSY.get_breakpoint_upperbounds(cost_data)
    static_cost = first.(cost_data)
    for i in 1:length(cost_data)
        JuMP.add_to_expression!(
            gen_cost,
            static_cost[i] * upb[i] * dt * pwl_var_container[(component_name, i, time_period)],
        )
    end
    return gen_cost
end
