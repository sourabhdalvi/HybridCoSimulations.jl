
function PSI.add_expressions!(
    container::PSI.OptimizationContainer,
    ::Type{T},
    devices::U,
    model::PSI.DeviceModel{D, W},
) where {
    T <: TotalProductionExpression,
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: PSI.AbstractDeviceFormulation,
} where {D <: PSY.Component}
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    PSI.add_expression_container!(container, T(), D, names)
    return
end

function PSI.add_expressions!(
    container::PSI.OptimizationContainer,
    ::Type{T},
    devices::U,
    model::PSI.DeviceModel{D, W},
) where {
    T <: ProductionLowerBoundExpression,
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: PSI.AbstractDeviceFormulation,
} where {D <: PSY.Component}
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    no_of_scenarios = get_no_of_scenarios(devices)
    PSI.add_expression_container!(container, T(), D, names, 1:no_of_scenarios, time_steps)
    return
end


function PSI.add_to_expression!(
    container::PSI.OptimizationContainer,
    ::Type{T},
    ::Type{U},
    devices::IS.FlattenIteratorWrapper{V},
    model::PSI.DeviceModel{V, W},
    ::Type{X},
) where {
    T <: ProductionUpperBoundExpression,
    U <: PSI.ActivePowerVariable,
    V <: PSY.HybridSystem,
    W <: PSI.AbstractHybridFormulation,
    X <: PM.AbstractPowerModel,
}
    variable = PSI.get_variable(container, U(), V)
    if !PSI.has_container_key(container, T, V)
        PSI.add_expressions!(container, T, devices, model)
    end
    expression = PSI.get_expression(container, T(), V)
    for d in devices, t in PSI.get_time_steps(container)
        name = PSY.get_name(d)
        for t1 in 1:t
            PSI._add_to_jump_expression!(expression[name, t], variable[name, t1], 1.0)
        end
    end
    return
end


function PSI.add_to_expression!(
    container::PSI.OptimizationContainer,
    ::Type{ProductionUpperBoundExpression},
    ::Type{U},
    devices::IS.FlattenIteratorWrapper{V},
    model::PSI.DeviceModel{V, W},
    ::Type{X},
) where {
    U <: CurtailedEnergy,
    V <: PSY.HybridSystem,
    W <: PSI.AbstractHybridFormulation,
    X <: PM.AbstractPowerModel,
}
    variable = PSI.get_variable(container, U(), V)
    if !PSI.has_container_key(container, ProductionUpperBoundExpression, V)
        PSI.add_expressions!(container, ProductionUpperBoundExpression, devices, model)
    end
    no_of_scenarios = get_no_of_scenarios(devices)
    expression = PSI.get_expression(container, ProductionUpperBoundExpression(), V)
    for d in devices, t in PSI.get_time_steps(container)
        name = PSY.get_name(d)
        for t1 in 1:t, r in 1:no_of_scenarios
            PSI._add_to_jump_expression!(expression[name, t], variable[name, r, t1], 1.0)
        end
    end
    return
end



function PSI.add_to_expression!(
    container::PSI.OptimizationContainer,
    ::Type{TotalProductionExpression},
    ::Type{U},
    devices::IS.FlattenIteratorWrapper{V},
    model::PSI.DeviceModel{V, W},
    ::Type{X},
) where {
    U <: PSI.ActivePowerVariable,
    V <: PSY.HybridSystem,
    W <: PSI.AbstractHybridFormulation,
    X <: PM.AbstractPowerModel,
}
    variable = PSI.get_variable(container, U(), V)
    if !PSI.has_container_key(container, TotalProductionExpression, V)
        PSI.add_expressions!(container, TotalProductionExpression, devices, model)
    end
    expression = PSI.get_expression(container, TotalProductionExpression(), V)
    for d in devices
        name = PSY.get_name(d)
        for t in PSI.get_time_steps(container)
            PSI._add_to_jump_expression!(expression[name], variable[name, t], 1.0)
        end
    end
    return
end


function PSI.add_to_expression!(
    container::PSI.OptimizationContainer,
    ::Type{TotalProductionExpression},
    ::Type{U},
    devices::IS.FlattenIteratorWrapper{V},
    model::PSI.DeviceModel{V, W},
    ::Type{X},
) where {
    U <: CurtailedEnergy,
    V <: PSY.HybridSystem,
    W <: PSI.AbstractHybridFormulation,
    X <: PM.AbstractPowerModel,
}
    variable = PSI.get_variable(container, U(), V)
    if !PSI.has_container_key(container, TotalProductionExpression, V)
        PSI.add_expressions!(container, TotalProductionExpression, devices, model)
    end
    no_of_scenarios = get_no_of_scenarios(devices)
    expression = PSI.get_expression(container, TotalProductionExpression(), V)
    for d in devices 
        name = PSY.get_name(d)
        for t in PSI.get_time_steps(container), r in 1:no_of_scenarios
            PSI._add_to_jump_expression!(expression[name], variable[name, r, t], 1.0)
        end
    end
    return
end


function PSI.add_to_expression!(
    container::PSI.OptimizationContainer,
    ::Type{ProductionLowerBoundExpression},
    ::Type{U},
    devices::IS.FlattenIteratorWrapper{V},
    model::PSI.DeviceModel{V, W},
    ::Type{X},
) where {
    U <: PSI.ActivePowerVariable,
    V <: PSY.HybridSystem,
    W <: HybridProbablisticDispatch,
    X <: PM.AbstractPowerModel,
}
    variable = PSI.get_variable(container, U(), V)
    if !PSI.has_container_key(container, ProductionLowerBoundExpression, V)
        PSI.add_expressions!(container, ProductionLowerBoundExpression, devices, model)
    end
    no_of_scenarios = get_no_of_scenarios(devices)
    expression = PSI.get_expression(container, ProductionLowerBoundExpression(), V)
    for d in devices, t in PSI.get_time_steps(container)
        name = PSY.get_name(d)
        for r in 1:no_of_scenarios
            for t1 in 1:t
                PSI._add_to_jump_expression!(expression[name, r, t], variable[name, t1], 1.0)
            end
        end
    end
    return
end


function PSI.add_to_expression!(
    container::PSI.OptimizationContainer,
    ::Type{ProductionLowerBoundExpression},
    ::Type{U},
    devices::IS.FlattenIteratorWrapper{V},
    model::PSI.DeviceModel{V, W},
    ::Type{X},
) where {
    U <: CurtailedEnergy,
    V <: PSY.HybridSystem,
    W <: PSI.AbstractHybridFormulation,
    X <: PM.AbstractPowerModel,
}
    variable = PSI.get_variable(container, U(), V)
    if !PSI.has_container_key(container, ProductionLowerBoundExpression, V)
        PSI.add_expressions!(container, ProductionLowerBoundExpression, devices, model)
    end
    no_of_scenarios = get_no_of_scenarios(devices)
    expression = PSI.get_expression(container, ProductionLowerBoundExpression(), V)
    for d in devices, t in PSI.get_time_steps(container)
        name = PSY.get_name(d)
        for r in 1:no_of_scenarios
            for t1 in 1:(t-1), r1 in r:no_of_scenarios[end]
                PSI._add_to_jump_expression!(expression[name, r, t], variable[name, r, t1], 1.0)
            end
        end
    end
    return
end
