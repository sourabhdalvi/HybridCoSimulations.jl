### Defining new formulation
struct HybridProbablisticDispatch <: PSI.AbstractHybridFormulation end

### Adding method for variables
PSI.get_variable_lower_bound(::PSI.ActivePowerVariable, d::PSY.HybridSystem, ::HybridProbablisticDispatch) = 0.0
PSI.get_variable_upper_bound(::PSI.ActivePowerVariable, d::PSY.HybridSystem, ::HybridProbablisticDispatch) = PSY.get_output_active_power_limits(d).max
PSI.get_variable_multiplier(::PSI.ActivePowerOutVariable, d::Type{<:PSY.HybridSystem}, ::HybridProbablisticDispatch) = 1.0

PSI.get_variable_binary(::CurtailedEnergy, ::Type{<:PSY.HybridSystem}, ::HybridProbablisticDispatch) = false
PSI.get_variable_lower_bound(::CurtailedEnergy, d::PSY.HybridSystem, ::HybridProbablisticDispatch) = 0.0
PSI.get_variable_upper_bound(::CurtailedEnergy, d::PSY.HybridSystem, ::HybridProbablisticDispatch) = PSY.get_rating(PSY.get_renewable_unit(d))
PSI.get_variable_multiplier(::CurtailedEnergy, d::Type{<:PSY.HybridSystem}, ::HybridProbablisticDispatch) = 1.0

PSI.get_variable_binary(::EnergyAboveInitial, ::Type{<:PSY.HybridSystem}, ::HybridProbablisticDispatch) = false
PSI.get_variable_lower_bound(::EnergyAboveInitial, d::PSY.HybridSystem, ::HybridProbablisticDispatch) = 0.0
PSI.get_variable_upper_bound(::EnergyAboveInitial, d::PSY.HybridSystem, ::HybridProbablisticDispatch) = PSY.get_state_of_charge_limits(PSY.get_storage(d)).max
PSI.get_variable_multiplier(::EnergyAboveInitial, d::Type{<:PSY.HybridSystem}, ::HybridProbablisticDispatch) = 1.0

PSI.get_variable_binary(::EnergySlackVariableK1, ::Type{<:PSY.HybridSystem}, ::HybridProbablisticDispatch) = false
PSI.get_variable_lower_bound(::EnergySlackVariableK1, d::PSY.HybridSystem, ::HybridProbablisticDispatch) = 0.0
PSI.get_variable_multiplier(::EnergySlackVariableK1, d::Type{<:PSY.HybridSystem}, ::HybridProbablisticDispatch) = 1.0

PSI.get_variable_binary(::EnergySlackVariableK2, ::Type{<:PSY.HybridSystem}, ::HybridProbablisticDispatch) = false
PSI.get_variable_lower_bound(::EnergySlackVariableK2, d::PSY.HybridSystem, ::HybridProbablisticDispatch) = 0.0
PSI.get_variable_multiplier(::EnergySlackVariableK2, d::Type{<:PSY.HybridSystem}, ::HybridProbablisticDispatch) = 1.0

### Adding methods for parameters
PSI.get_multiplier_value(::PSI.ActivePowerTimeSeriesParameter, d::PSY.HybridSystem,  ::HybridProbablisticDispatch) = PSY.get_output_active_power_limits(d).max
PSI.get_multiplier_value(::MaximumEnergyParameter, d::PSY.HybridSystem,  ::HybridProbablisticDispatch) = PSY.get_state_of_charge_limits(PSY.get_storage(d)).max
PSI.get_multiplier_value(::MinimumEnergyParameter, d::PSY.HybridSystem,  ::HybridProbablisticDispatch) = PSY.get_state_of_charge_limits(PSY.get_storage(d)).max
PSI.get_multiplier_value(::TotalEnergyParameter, d::PSY.HybridSystem,  ::HybridProbablisticDispatch) = PSY.get_state_of_charge_limits(PSY.get_storage(d)).max
PSI.get_multiplier_value(::ProductionLowerBoundParameter, d::PSY.HybridSystem,  ::HybridProbablisticDispatch) = PSY.get_output_active_power_limits(d).max

function PSI.get_default_time_series_names(
    ::Type{PSY.HybridSystem},
    ::Type{HybridProbablisticDispatch},
)
    return Dict{Type{<:PSI.TimeSeriesParameter}, String}(
        PSI.ActivePowerTimeSeriesParameter => "max_active_power",
        MaximumEnergyParameter => "max_energy",
        MinimumEnergyParameter => "min_energy",
        TotalEnergyParameter => "total_energy",
        ProductionLowerBoundParameter => "production_lower_bound",
    )
end

### Defining custom constraints

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{PSI.ActivePowerVariableLimitsConstraint},
    U::Type{<:Union{PSI.VariableType, PSI.ExpressionType}},
    devices::IS.FlattenIteratorWrapper{V},
    model::PSI.DeviceModel{V, W},
    X::Type{<:PM.AbstractPowerModel},
) where {V <: PSY.HybridSystem, W <: HybridProbablisticDispatch}
    PSI.add_parameterized_upper_bound_range_constraints(
        container,
        PSI.ActivePowerVariableTimeSeriesLimitsConstraint,
        U,
        PSI.ActivePowerTimeSeriesParameter,
        devices,
        model,
        X,
    )
    return
end

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{VariableUpperBoundConstraint},
    U::Type{ProductionUpperBoundExpression},
    devices::IS.FlattenIteratorWrapper{V},
    model::PSI.DeviceModel{V, W},
    ::Type{X},
) where {
    V <: PSY.HybridSystem,
    W <: HybridProbablisticDispatch,
    X <: PM.AbstractPowerModel,
}
    time_steps = PSI.get_time_steps(container)
    resolution = PSI.get_resolution(container)
    names = [PSY.get_name(x) for x in devices]

    # curatiled_energy_var = get_variable(container, CurtailedEnergy(), V)
    # power_var = get_variable(container, ActivePowerVariable(), V)
    expression_vars = PSI.get_expression(container, U(), V)

    constraint = PSI.add_constraints_container!(
        container,
        T(),
        V,
        names,
        time_steps,
    )
    
    param = PSI.get_parameter_array(container, MaximumEnergyParameter(), V)
    multiplier = PSI.get_parameter_multiplier_array(container, MaximumEnergyParameter(), V)

    for device in devices
        name = PSY.get_name(device)
        for t in time_steps
            constraint[name, t] = JuMP.@constraint(
                container.JuMPmodel,
                expression_vars[name, t] <= param[name, t] * multiplier[name, t]
            )
        end
    end
    return
end

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{VariableLowerBoundConstraint},
    U::Type{ProductionLowerBoundExpression},
    devices::IS.FlattenIteratorWrapper{V},
    model::PSI.DeviceModel{V, W},
    ::Type{X},
) where {
    V <: PSY.HybridSystem,
    W <: HybridProbablisticDispatch,
    X <: PM.AbstractPowerModel,
}
    time_steps = PSI.get_time_steps(container)
    resolution = PSI.get_resolution(container)
    names = [PSY.get_name(x) for x in devices]
    no_of_scenarios = get_no_of_scenarios(devices)
    # curatiled_energy_var = get_variable(container, CurtailedEnergy(), V)
    # power_var = get_variable(container, ActivePowerVariable(), V)
    expression_vars = PSI.get_expression(container, U(), V)

    constraint = PSI.add_constraints_container!(
        container,
        T(),
        V,
        names,
        1:no_of_scenarios,
        time_steps,
    )
    
    param = PSI.get_parameter_array(container, ProductionLowerBoundParameter(), V)
    multiplier = PSI.get_parameter_multiplier_array(container, ProductionLowerBoundParameter(), V)

    for device in devices
        name = PSY.get_name(device)
        for t in time_steps, r in 1:no_of_scenarios
            constraint[name, r, t] = JuMP.@constraint(
                container.JuMPmodel,
                expression_vars[name, r, t] >= param[name, r, t] * multiplier[name, r, t]
            )
        end
    end
    return
end

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{TotalProductionLimitConstraint},
    U::Type{TotalProductionExpression},
    devices::IS.FlattenIteratorWrapper{V},
    model::PSI.DeviceModel{V, W},
    ::Type{X},
) where {
    V <: PSY.HybridSystem,
    W <: HybridProbablisticDispatch,
    X <: PM.AbstractPowerModel,
}
    time_steps = PSI.get_time_steps(container)
    resolution = PSI.get_resolution(container)
    names = [PSY.get_name(x) for x in devices]
    initial_conditions = PSI.get_initial_condition(container, PSI.InitialEnergyLevel(), V)
    # curatiled_energy_var = get_variable(container, CurtailedEnergy(), V)
    # power_var = get_variable(container, ActivePowerVariable(), V)
    theta_var = PSI.get_variable(container, EnergyAboveInitial(), V)
    total_production_expr = PSI.get_expression(container, U(), V)
    
    constraint = PSI.add_constraints_container!(
        container,
        T(),
        V,
        names,
    )
    
    param = PSI.get_parameter_array(container, MaximumEnergyParameter(), V)
    multiplier = PSI.get_parameter_multiplier_array(container, MaximumEnergyParameter(), V)

    for ic in initial_conditions
        device = PSI.get_component(ic)
        name = PSY.get_name(device)
        eff = PSY.get_efficiency(PSY.get_storage(device)).in
        constraint[name] = JuMP.@constraint(
            container.JuMPmodel,
            total_production_expr[name] >= param[name, time_steps[end]] * multiplier[name, time_steps[end]] 
            - eff*(PSI.get_value(ic) - theta_var[name])
        )
    end
    return
end

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{ResidualEnergyBoundConstraint},
    U::Type{EnergyAboveInitial},
    devices::IS.FlattenIteratorWrapper{V},
    model::PSI.DeviceModel{V, W},
    ::Type{X},
) where {
    V <: PSY.HybridSystem,
    W <: HybridProbablisticDispatch,
    X <: PM.AbstractPowerModel,
}
    time_steps = PSI.get_time_steps(container)
    resolution = PSI.get_resolution(container)
    names = [PSY.get_name(x) for x in devices]
    initial_conditions = PSI.get_initial_condition(container, PSI.InitialEnergyLevel(), V)
    # curatiled_energy_var = get_variable(container, CurtailedEnergy(), V)
    # power_var = get_variable(container, ActivePowerVariable(), V)
    theta_var = PSI.get_variable(container, U(), V)

    
    constraint = PSI.add_constraints_container!(
        container,
        T(),
        V,
        names,
        1:2,
    )
    
    param_total_E = PSI.get_parameter_array(container, TotalEnergyParameter(), V)
    multiplier_total_E = PSI.get_parameter_multiplier_array(container, TotalEnergyParameter(), V)
    
    param_ub = PSI.get_parameter_array(container, MaximumEnergyParameter(), V)
    multiplier_ub = PSI.get_parameter_multiplier_array(container, MaximumEnergyParameter(), V)

    for ic in initial_conditions
        device = PSI.get_component(ic)
        name = PSY.get_name(device)
        eff = PSY.get_efficiency(PSY.get_storage(device)).in
        Emax = PSY.get_state_of_charge_limits(PSY.get_storage(device)).max
        
        constraint[name, 1] = JuMP.@constraint(container.JuMPmodel,
            theta_var[name] <= Emax - PSI.get_value(ic)
        )

        constraint[name, 2] = JuMP.@constraint(container.JuMPmodel,
            theta_var[name] >= (param_ub[name, time_steps[end]]* multiplier_ub[name, time_steps[end]] - eff * PSI.get_value(ic))
                /(eff - param_total_E[name]* multiplier_total_E[name])
        )
    end
    return
end


function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{EnergyInitialConditionConstraint},
    U::Type{EnergyAboveInitial},
    devices::IS.FlattenIteratorWrapper{V},
    model::PSI.DeviceModel{V, W},
    ::Type{X},
) where {
    V <: PSY.HybridSystem,
    W <: HybridProbablisticDispatch,
    X <: PM.AbstractPowerModel,
}
    time_steps = PSI.get_time_steps(container)
    resolution = PSI.get_resolution(container)
    names = [PSY.get_name(x) for x in devices]
    initial_conditions = PSI.get_initial_condition(container, PSI.InitialEnergyLevel(), V)
    slack_varK1 = PSI.get_variable(container, EnergySlackVariableK1(), V)
    slack_varK2 = PSI.get_variable(container, EnergySlackVariableK2(), V)
    theta_var = PSI.get_variable(container, EnergyAboveInitial(), V)
    
    constraint = PSI.add_constraints_container!(
        container,
        T(),
        V,
        names,
        1:2,
    )
    

    for ic in initial_conditions
        device = PSI.get_component(ic)
        name = PSY.get_name(device)
        eff = PSY.get_efficiency(PSY.get_storage(device)).in
        constraint[name, 1] = JuMP.@constraint(
            container.JuMPmodel,
            theta_var[name] + PSI.get_value(ic) + slack_varK1[name] + slack_varK2[name] >= 2.0 * 400.0
        )
        constraint[name, 2] = JuMP.@constraint(
            container.JuMPmodel,
            theta_var[name] + PSI.get_value(ic) + slack_varK1[name] >= 2.0 * 300.0
        )
    end
    return
end
