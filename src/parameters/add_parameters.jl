function PSI.add_parameters!(
    container::PSI.OptimizationContainer,
    ::T,
    devices::U,
    model::PSI.DeviceModel{D, W},
) where {
    T <: PSI.ActivePowerTimeSeriesParameter,
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: HybridProbablisticDispatch,
} where {D <: PSY.HybridSystem}
    ts_type = PSI.get_default_time_series_type(container)
    if !(ts_type <: Union{PSY.AbstractDeterministic, PSY.StaticTimeSeries})
        error("add_parameters! for TimeSeriesParameter is not compatible with $ts_type")
    end
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    ts_name = PSI.get_time_series_names(model)[T]
    time_series_mult_id = PSI.create_time_series_multiplier_index(model, T)
    @debug "adding" T ts_name ts_type time_series_mult_id _group =
        PSI.LOG_GROUP_OPTIMIZATION_CONTAINER
    parameter_container =
        PSI.add_param_container!(container, T(), D, ts_type, ts_name, names, time_steps)
    PSI.set_time_series_multiplier_id!(PSI.get_attributes(parameter_container), time_series_mult_id)
    jump_model = PSI.get_jump_model(container)
    for d in devices
        name = PSY.get_name(d)
        ts_vector = PSI.get_time_series(container, d, T())
        multiplier = PSI.get_multiplier_value(T(), d, W())
        for t in time_steps
            PSI.set_parameter!(
                parameter_container,
                jump_model,
                ts_vector[t],
                multiplier,
                name,
                t,
            )
        end
    end
    return
end


function PSI.add_parameters!(
    container::PSI.OptimizationContainer,
    ::T,
    devices::U,
    model::PSI.DeviceModel{D, W},
) where {
    T <: TotalEnergyParameter,
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: PSI.AbstractHybridFormulation,
} where {D <: PSY.HybridSystem}
    ts_type = PSI.PSI.get_default_time_series_type(container)
    if !(ts_type <: Union{PSY.AbstractDeterministic, PSY.StaticTimeSeries})
        error("add_parameters! for TimeSeriesParameter is not compatible with $ts_type")
    end
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    ts_name = PSI.get_time_series_names(model)[T]
    time_series_mult_id = PSI.create_time_series_multiplier_index(model, T)
    @debug "adding" T ts_name ts_type time_series_mult_id _group =
        PSI.LOG_GROUP_OPTIMIZATION_CONTAINER
    parameter_container =
        PSI.add_param_container!(container, T(), D, ts_type, ts_name, names)
    PSI.set_time_series_multiplier_id!(PSI.get_attributes(parameter_container), time_series_mult_id)
    jump_model = PSI.get_jump_model(container)
    for d in devices
        name = PSY.get_name(d)
        ts_vector = PSI.get_time_series(container, d, T())
        multiplier = PSI.get_multiplier_value(T(), d, W())

        PSI.set_parameter!(
            parameter_container,
            jump_model,
            ts_vector[1],
            multiplier,
            name,
        )
    end
    return
end


function PSI.add_parameters!(
    container::PSI.OptimizationContainer,
    ::T,
    devices::U,
    model::PSI.DeviceModel{D, W},
) where {
    T <: ProductionLowerBoundParameter,
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: PSI.AbstractHybridFormulation,
} where {D <: PSY.HybridSystem}
    ts_type = PSI.PSI.get_default_time_series_type(container)
    if !(ts_type <: Union{PSY.AbstractDeterministic, PSY.StaticTimeSeries})
        error("add_parameters! for TimeSeriesParameter is not compatible with $ts_type")
    end
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    ts_name = PSI.get_time_series_names(model)[T]
    no_of_scenarios = get_no_of_scenarios(devices)
    time_series_mult_id = PSI.create_time_series_multiplier_index(model, T)
    @debug "adding" T ts_name ts_type time_series_mult_id _group =
        PSI.LOG_GROUP_OPTIMIZATION_CONTAINER
    parameter_container =
        PSI.add_param_container!(container, T(), D, ts_type, ts_name, names, 1:no_of_scenarios, time_steps)
    PSI.set_time_series_multiplier_id!(PSI.get_attributes(parameter_container), time_series_mult_id)
    jump_model = PSI.get_jump_model(container)

    for d in devices
        name = PSY.get_name(d)
        ts_vector = PSI.get_time_series(container, d, T())
        multiplier = PSI.get_multiplier_value(T(), d, W())
        for t in time_steps, r in 1:no_of_scenarios
            PSI.set_parameter!(
                parameter_container,
                jump_model,
                ts_vector[1],
                multiplier,
                name,
                r,
                t,
            )
        end
    end
    return
end
