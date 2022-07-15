### Adding constructor for new formulation

function PSI.construct_device!(
    container::PSI.OptimizationContainer,
    sys::PSY.System,
    ::PSI.ArgumentConstructStage,
    model::PSI.DeviceModel{T, D},
    ::Type{S},
) where {
    T <: PSY.HybridSystem,
    D <: HybridProbablisticDispatch,
    S <: PM.AbstractActivePowerModel,
}

    devices = PSI.get_available_components(T, sys)

    # Variables
    PSI.add_variables!(container, PSI.ActivePowerVariable, devices, D())
    PSI.add_variables!(container, CurtailedEnergy, devices, D())
    PSI.add_variables!(container, EnergyAboveInitial, devices, D())
    PSI.add_variables!(container, EnergySlackVariableK1, devices, D())
    PSI.add_variables!(container, EnergySlackVariableK2, devices, D())
    
    # Parameters
    PSI.add_parameters!(container, PSI.ActivePowerTimeSeriesParameter, devices, model)
    PSI.add_parameters!(container, MaximumEnergyParameter, devices, model) # for all T
    PSI.add_parameters!(container, MinimumEnergyParameter, devices, model) # for all t
    PSI.add_parameters!(container, TotalEnergyParameter, devices, model) # single value parameter
    PSI.add_parameters!(container, ProductionLowerBoundParameter, devices, model) # for all r, t
    PSI.add_parameters!(container, ThetaLowerBoundParameter, devices, model)
    
   # Initial Conditions
   PSI.initial_conditions!(container, devices, D())

   PSI.add_to_expression!(
        container,
        PSI.ActivePowerBalance,
        PSI.ActivePowerVariable,
        devices,
        model,
        S,
    )
   PSI.add_to_expression!(
        container,
        ProductionUpperBoundExpression,
        PSI.ActivePowerVariable,
        devices,
        model,
        S,
    )
    PSI.add_to_expression!(
        container,
        TotalProductionExpression,
        PSI.ActivePowerVariable,
        devices,
        model,
        S,
    )
    PSI.add_to_expression!(
        container,
        ProductionLowerBoundExpression,
        PSI.ActivePowerVariable,
        devices,
        model,
        S,
    )
    
    PSI.add_to_expression!(
        container,
        ProductionUpperBoundExpression,
        CurtailedEnergy,
        devices,
        model,
        S,
    )
    PSI.add_to_expression!(
        container,
        TotalProductionExpression,
        CurtailedEnergy,
        devices,
        model,
        S,
    )
    PSI.add_to_expression!(
        container,
        ProductionLowerBoundExpression,
        CurtailedEnergy,
        devices,
        model,
        S,
    )

    return
end



function PSI.construct_device!(
    container::PSI.OptimizationContainer,
    sys::PSY.System,
    ::PSI.ModelConstructStage,
    model::PSI.DeviceModel{T, D},
    ::Type{S},
) where {
    T <: PSY.HybridSystem,
    D <: HybridProbablisticDispatch,
    S <: PM.AbstractActivePowerModel,
}
    
    devices = PSI.get_available_components(T, sys)
    
    # Constraints
    PSI.add_constraints!(
        container,
        PSI.ActivePowerVariableLimitsConstraint,
        PSI.ActivePowerVariable,
        devices,
        model,
        S,
    )
    PSI.add_constraints!(
        container,
        VariableUpperBoundConstraint,
        ProductionUpperBoundExpression,
        devices,
        model,
        S,
    )
    PSI.add_constraints!(
        container,
        VariableLowerBoundConstraint,
        ProductionLowerBoundExpression,
        devices,
        model,
        S,
    )
    PSI.add_constraints!(
        container,
        TotalProductionLimitConstraint,
        TotalProductionExpression,
        devices,
        model,
        S,
    )
    PSI.add_constraints!(
        container,
        ResidualEnergyBoundConstraint,
        EnergyAboveInitial,
        devices,
        model,
        S,
    )
    # PSI.add_constraints!(
    #     container,
    #     EnergyInitialConditionConstraint,
    #     EnergyAboveInitial,
    #     devices,
    #     model,
    #     S,
    # )
    PSI.add_constraints!(
        container,
        EnergyAboveInitialTimeConstraint,
        EnergyAboveInitial,
        devices,
        model,
        S,
    )
    PSI.add_constraints!(
        container,
        EnergySlackVariableK1TimeConstraint,
        EnergySlackVariableK1,
        devices,
        model,
        S,
    )
    PSI.add_constraints!(
        container,
        EnergySlackVariableK2TimeConstraint,
        EnergySlackVariableK2,
        devices,
        model,
        S,
    )
    
    PSI.add_feedforward_constraints!(container, model, devices)
    
    # Cost Function
    PSI.objective_function!(container, devices, model, S)

    return
end


### Adding constructor for new formulation

function PSI.construct_device!(
    container::PSI.OptimizationContainer,
    sys::PSY.System,
    ::PSI.ArgumentConstructStage,
    model::PSI.DeviceModel{T, D},
    ::Type{S},
) where {
    T <: PSY.HybridSystem,
    D <: HybridProbablisticCostDispatch,
    S <: PM.AbstractActivePowerModel,
}

    devices = PSI.get_available_components(T, sys)

    # Variables
    PSI.add_variables!(container, PSI.ActivePowerVariable, devices, D())
    PSI.add_variables!(container, EnergyAuxVariable, devices, D())
    # PSI.add_variables!(container, CostBidAuxVariable, devices, D())

    # Parameters
    PSI.add_parameters!(container, PSI.ActivePowerTimeSeriesParameter, devices, model)
    PSI.add_parameters!(container, PowerScheduledParameter, devices, model) # for all T
    PSI.add_parameters!(container, CalculatedCostParameter, devices, model)
   # Initial Conditions
   PSI.initial_conditions!(container, devices, D())

   PSI.add_to_expression!(
        container,
        PSI.ActivePowerBalance,
        PSI.ActivePowerVariable,
        devices,
        model,
        S,
    )
 
    return
end

function PSI.construct_device!(
    container::PSI.OptimizationContainer,
    sys::PSY.System,
    ::PSI.ModelConstructStage,
    model::PSI.DeviceModel{T, D},
    ::Type{S},
) where {
    T <: PSY.HybridSystem,
    D <: HybridProbablisticCostDispatch,
    S <: PM.AbstractActivePowerModel,
}
    
    devices = PSI.get_available_components(T, sys)
    
    # Constraints
    # PSI.add_constraints!(
    #     container,
    #     PSI.ActivePowerVariableLimitsConstraint,
    #     PSI.ActivePowerVariable,
    #     devices,
    #     model,
    #     S,
    # )
    
    PSI.add_feedforward_constraints!(container, model, devices)
    
    # Cost Function
    PSI.objective_function!(container, devices, model, S)

    return
end
