### Defining new formulation
struct HybridProbablisticDispatch <: PSI.AbstractHybridFormulation end
struct HybridProbablisticCostDispatch <: PSI.AbstractHybridFormulation end
### Adding method for variables
PSI.get_variable_lower_bound(::PSI.ActivePowerVariable, d::PSY.HybridSystem, ::HybridProbablisticDispatch) = 0.0
PSI.get_variable_upper_bound(::PSI.ActivePowerVariable, d::PSY.HybridSystem, ::HybridProbablisticDispatch) = nothing #PSY.get_output_active_power_limits(d).max
PSI.get_variable_multiplier(::PSI.ActivePowerOutVariable, d::Type{<:PSY.HybridSystem}, ::HybridProbablisticDispatch) = 1.0

PSI.get_variable_binary(::CurtailedEnergy, ::Type{<:PSY.HybridSystem}, ::HybridProbablisticDispatch) = false
PSI.get_variable_lower_bound(::CurtailedEnergy, d::PSY.HybridSystem, ::HybridProbablisticDispatch) = 0.0
PSI.get_variable_upper_bound(::CurtailedEnergy, d::PSY.HybridSystem, ::HybridProbablisticDispatch) = PSY.get_rating(PSY.get_renewable_unit(d))
PSI.get_variable_multiplier(::CurtailedEnergy, d::Type{<:PSY.HybridSystem}, ::HybridProbablisticDispatch) = 1.0

PSI.get_variable_binary(::EnergyAboveInitial, ::Type{<:PSY.HybridSystem}, ::HybridProbablisticDispatch) = false
PSI.get_variable_lower_bound(::EnergyAboveInitial, d::PSY.HybridSystem, ::HybridProbablisticDispatch) = nothing
PSI.get_variable_upper_bound(::EnergyAboveInitial, d::PSY.HybridSystem, ::HybridProbablisticDispatch) = nothing
PSI.get_variable_multiplier(::EnergyAboveInitial, d::Type{<:PSY.HybridSystem}, ::HybridProbablisticDispatch) = 1.0

PSI.get_variable_binary(::EnergySlackVariableK1, ::Type{<:PSY.HybridSystem}, ::HybridProbablisticDispatch) = false
PSI.get_variable_lower_bound(::EnergySlackVariableK1, d::PSY.HybridSystem, ::HybridProbablisticDispatch) = 0.0
PSI.get_variable_multiplier(::EnergySlackVariableK1, d::Type{<:PSY.HybridSystem}, ::HybridProbablisticDispatch) = 1.0

PSI.get_variable_binary(::EnergySlackVariableK2, ::Type{<:PSY.HybridSystem}, ::HybridProbablisticDispatch) = false
PSI.get_variable_lower_bound(::EnergySlackVariableK2, d::PSY.HybridSystem, ::HybridProbablisticDispatch) = 0.0
PSI.get_variable_multiplier(::EnergySlackVariableK2, d::Type{<:PSY.HybridSystem}, ::HybridProbablisticDispatch) = 1.0

### Adding methods for parameters
PSI.get_multiplier_value(::PSI.ActivePowerTimeSeriesParameter, d::PSY.HybridSystem,  ::HybridProbablisticDispatch) = 1.0
PSI.get_multiplier_value(::PSI.ActivePowerTimeSeriesParameter, d::PSY.HybridSystem,  ::HybridProbablisticCostDispatch) = 1.0
PSI.get_multiplier_value(::MaximumEnergyParameter, d::PSY.HybridSystem,  ::HybridProbablisticDispatch) = 1.0
PSI.get_multiplier_value(::MinimumEnergyParameter, d::PSY.HybridSystem,  ::HybridProbablisticDispatch) = 1.0
PSI.get_multiplier_value(::TotalEnergyParameter, d::PSY.HybridSystem,  ::HybridProbablisticDispatch) = 1.0
PSI.get_multiplier_value(::ProductionLowerBoundParameter, d::PSY.HybridSystem,  ::HybridProbablisticDispatch) = 1.0
PSI.get_multiplier_value(::ThetaLowerBoundParameter, d::PSY.HybridSystem,  ::HybridProbablisticDispatch) = 1.0
PSI.initial_condition_default(::InitialEnergyHybrid, d::PSY.HybridSystem, ::PSI.AbstractHybridFormulation) = PSY.get_initial_energy(PSY.get_storage(d))
PSI.initial_condition_variable(::InitialEnergyHybrid, d::PSY.HybridSystem, ::PSI.AbstractHybridFormulation) = EnergyAboveInitial()

PSI.initial_condition_default(::InitialEnergyLevelHybrid, d::PSY.HybridSystem, ::HybridProbablisticCostDispatch) = PSY.get_initial_energy(PSY.get_storage(d))
PSI.initial_condition_variable(::InitialEnergyLevelHybrid, d::PSY.HybridSystem, ::HybridProbablisticCostDispatch) = EnergyAuxVariable()

PSI.get_initial_parameter_value(::PowerScheduledParameter, d::PSY.HybridSystem, ::PSI.AbstractHybridFormulation) = 0.0
PSI.get_parameter_multiplier(::PowerScheduledParameter, d::PSY.HybridSystem, ::PSI.AbstractHybridFormulation) = 1.0

PSI.get_initial_parameter_value(::PowerPriceParameter, d::PSY.HybridSystem, ::PSI.AbstractHybridFormulation) = 0.0
PSI.get_parameter_multiplier(::PowerPriceParameter, d::PSY.HybridSystem, ::PSI.AbstractHybridFormulation) = 1.0

PSI.get_multiplier_value(::CalculatedCostParameter, d::PSY.HybridSystem,  ::HybridProbablisticCostDispatch) = 1.0
# PSI.objective_function_multiplier(::VariableType, ::AbstractHybridFormulation)=OBJECTIVE_FUNCTION_POSITIVE

function PSI.get_default_time_series_names(
    ::Type{PSY.HybridSystem},
    ::Type{U},
) where U <: Union{HybridProbablisticDispatch, HybridProbablisticCostDispatch}
    return Dict{Type{<:PSI.TimeSeriesParameter}, String}(
        PSI.ActivePowerTimeSeriesParameter => "max_active_power",
        MaximumEnergyParameter => "max_energy",
        MinimumEnergyParameter => "min_energy",
        TotalEnergyParameter => "total_energy",
        ProductionLowerBoundParameter => "production_lower_bound",
        ThetaLowerBoundParameter => "theta_lb",
        CalculatedCostParameter => "temp_cost",
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
                container.JuMPmodel, base_name = "con26($t)",
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
    initial_conditions = PSI.get_initial_condition(container, InitialEnergyHybrid(), V)
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
        E0 = PSY.get_initial_energy(PSY.get_storage(device))
        constraint[name] = JuMP.@constraint(
            container.JuMPmodel,
            total_production_expr[name] <= param[name, time_steps[end]] * multiplier[name, time_steps[end]] 
            - eff*(E0 + theta_var[name,1])
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
    initial_conditions = PSI.get_initial_condition(container, InitialEnergyHybrid(), V)
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

    # param_lb = PSI.get_parameter_array(container, ThetaLowerBoundParameter(), V)
    # multiplier_lb = PSI.get_parameter_multiplier_array(container, ThetaLowerBoundParameter(), V)

    for ic in initial_conditions
        device = PSI.get_component(ic)
        name = PSY.get_name(device)
        eff = PSY.get_efficiency(PSY.get_storage(device)).in
        E0 = PSY.get_initial_energy(PSY.get_storage(device))
        Emax = PSY.get_state_of_charge_limits(PSY.get_storage(device)).max
        
        constraint[name, 1] = JuMP.@constraint(container.JuMPmodel,
            theta_var[name, 1] <= Emax - E0
        )

        constraint[name, 2] = JuMP.@constraint(container.JuMPmodel,
            theta_var[name, 1] >= (param_ub[name, time_steps[end]]* multiplier_ub[name, time_steps[end]] - eff * E0)/eff
                - param_total_E[name, 1]* multiplier_total_E[name, 1]
        )
        # constraint[name, 2] = JuMP.@constraint(container.JuMPmodel,
        #     theta_var[name, 1] >= param_lb[name, time_steps[end]]* multiplier_lb[name, time_steps[end]]
        # )
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
    initial_conditions = PSI.get_initial_condition(container, InitialEnergyHybrid(), V)
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
        E0 = PSY.get_initial_energy(PSY.get_storage(device))
        constraint[name, 1] = JuMP.@constraint(
            container.JuMPmodel,
            theta_var[name, 1] + E0 + slack_varK1[name, 1] + slack_varK2[name, 1] >= 1.07
        )
        constraint[name, 2] = JuMP.@constraint(
            container.JuMPmodel,
            theta_var[name, 1] + E0 + slack_varK1[name, 1] >= 0.5*1.07
        )
    end
    return
end

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{<:SingleTimeDimensionConstraint},
    U::Type{S},
    devices::IS.FlattenIteratorWrapper{V},
    model::PSI.DeviceModel{V, W},
    ::Type{X},
) where {
    S <: PSI.VariableType,
    V <: PSY.HybridSystem,
    W <: HybridProbablisticDispatch,
    X <: PM.AbstractPowerModel,
}
    time_steps = PSI.get_time_steps(container)
    resolution = PSI.get_resolution(container)
    names = [PSY.get_name(x) for x in devices]
    var = PSI.get_variable(container, S(), V)
    constraint = PSI.add_constraints_container!(
        container,
        T(),
        V,
        names,
        time_steps,
    )

    for name in names, t in time_steps
        constraint[name, t] = JuMP.@constraint(
            container.JuMPmodel,
            var[name, t] == var[name, 1]
        )
    end
    return
end

function PSI.initial_conditions!(
    container::PSI.OptimizationContainer,
    devices::PSI.IS.FlattenIteratorWrapper{D},
    formulation::HybridProbablisticDispatch,
) where {D <: PSY.HybridSystem}
    PSI.add_initial_condition!(container, devices, formulation, InitialEnergyHybrid())
    return
end

function PSI.initial_conditions!(
    container::PSI.OptimizationContainer,
    devices::PSI.IS.FlattenIteratorWrapper{D},
    formulation::HybridProbablisticCostDispatch,
) where {D <: PSY.HybridSystem}
    PSI.add_initial_condition!(container, devices, formulation, InitialEnergyLevelHybrid())
    return
end

function PSI.calculate_aux_variable_value!(
    container::PSI.OptimizationContainer,
    ::PSI.AuxVarKey{EnergyAuxVariable, T},
    system::PSY.System,
) where {T <: PSY.HybridSystem}
    devices = PSI.get_available_components(T, system)
    time_steps = PSI.get_time_steps(container)
    resolution = PSI.get_resolution(container)
    fraction_of_hour = Dates.value(Dates.Minute(resolution)) / PSI.MINUTES_IN_HOUR

    p_variable = PSI.get_variable(container, PSI.ActivePowerVariable(), T)
    aux_variable_container = PSI.get_aux_variable(container, EnergyAuxVariable(), T)
    da_bid_param = PSI.get_parameter_array(container, PowerScheduledParameter(), T)
    da_multiplier = PSI.get_parameter_multiplier_array(container, PowerScheduledParameter(), T)
    initial_energy = PSI.get_initial_condition(container, InitialEnergyLevelHybrid(), T)
    active_power_param = PSI.get_parameter_array(container, PSI.ActivePowerTimeSeriesParameter(), T)
    active_power_multiplier = PSI.get_parameter_multiplier_array(container, PSI.ActivePowerTimeSeriesParameter(), T)
    for ic in initial_energy, t in time_steps
        d  = ic.component
        name = PSY.get_name(d)
        input_limit = PSY.get_input_active_power_limits(PSY.get_storage(d)).max
        output_limit = PSY.get_output_active_power_limits(PSY.get_storage(d)).max
        bat_cap = PSY.get_state_of_charge_limits(PSY.get_storage(d))
        eff = PSY.get_efficiency(PSY.get_storage(d))
        charging = JuMP.value(active_power_param[name, t]) - JuMP.value(p_variable[name, t])
        discharging = JuMP.value(p_variable[name, t]) - JuMP.value(active_power_param[name, t])
        aux_variable_container[name, t] = min(bat_cap.max, max(bat_cap.min, JuMP.value(PSI.get_value(ic)) + fraction_of_hour * eff.in * max(0, min(charging, input_limit)) - (fraction_of_hour/eff.out) * max(0, min(discharging, output_limit))))

    end

    return
end


function PSI.objective_function!(
    container::PSI.OptimizationContainer,
    devices::PSI.IS.FlattenIteratorWrapper{T},
    ::PSI.DeviceModel{T, U},
    ::Type{<:PSI.PM.AbstractPowerModel},
) where {T <: PSY.HybridSystem, U <: HybridProbablisticDispatch}
    # add_slack_k1_cost!(container, EnergySlackVariableK1(), devices, U())
    # add_slack_k2_cost!(container, EnergySlackVariableK2(), devices, U())
    # add_curtailment_cost!(container, CurtailedEnergy(), devices, U())
    return
end
