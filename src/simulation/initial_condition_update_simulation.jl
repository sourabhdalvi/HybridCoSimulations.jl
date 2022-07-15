function PSI._update_initial_conditions!(
    model::PSI.OperationModel,
    key::PSI.ICKey{T, U},
    source, # Store or State are used in simulations by default
) where {T <: InitialEnergyHybrid, U <: PSY.HybridSystem}
    if PSI.get_execution_count(model) < 1
        return
    end

    container = PSI.get_optimization_container(model)
    model_resolution = PSI.get_resolution(model.internal.store_parameters)
    ini_conditions_vector = PSI.get_initial_condition(container, key)
    timestamp = PSI.get_current_timestamp(model)
    previous_values = PSI.get_condition.(ini_conditions_vector)
    # The implementation of specific update_initial_conditions! is located in the files
    # update_initial_conditions_in_memory_store.jl and update_initial_conditions_simulation.jl
    # update_initial_conditions!(ini_conditions_vector, source, model_resolution)
    for ic in ini_conditions_vector
        var_val = PSI.get_system_state_value(source, EnergyAboveInitial(), PSI.get_component_type(ic))
        previous_ic_value =  JuMP.value(PSI.get_value(ic))
        val = previous_ic_value + var_val[PSI.get_component_name(ic)]
        PSI.set_ic_quantity!(ic, val)
    end
    for (i, initial_condition) in enumerate(ini_conditions_vector)
        IS.@record :execution PSI.InitialConditionUpdateEvent(
            timestamp,
            initial_condition,
            previous_values[i],
            PSI.get_name(model),
        )
    end
    return
end


function PSI._update_initial_conditions!(
    model::PSI.OperationModel,
    key::PSI.ICKey{T, U},
    source, # Store or State are used in simulations by default
) where {T <: InitialEnergyLevelHybrid, U <: PSY.HybridSystem}
    if PSI.get_execution_count(model) < 1
        return
    end

    container = PSI.get_optimization_container(model)
    model_resolution = PSI.get_resolution(model.internal.store_parameters)
    ini_conditions_vector = PSI.get_initial_condition(container, key)
    timestamp = PSI.get_current_timestamp(model)
    previous_values = PSI.get_condition.(ini_conditions_vector)
    # The implementation of specific update_initial_conditions! is located in the files
    # update_initial_conditions_in_memory_store.jl and update_initial_conditions_simulation.jl
    # update_initial_conditions!(ini_conditions_vector, source, model_resolution)
    for ic in ini_conditions_vector
        var_val = PSI.get_system_state_value(source, EnergyAuxVariable(), PSI.get_component_type(ic))
        val = var_val[PSI.get_component_name(ic)]
        PSI.set_ic_quantity!(ic, val)
    end
    for (i, initial_condition) in enumerate(ini_conditions_vector)
        IS.@record :execution PSI.InitialConditionUpdateEvent(
            timestamp,
            initial_condition,
            previous_values[i],
            PSI.get_name(model),
        )
    end
    return
end

