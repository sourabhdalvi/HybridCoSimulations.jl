function PSI.add_parameters!(
    container::PSI.OptimizationContainer,
    ::Type{T},
    devices::U,
    model::PSI.DeviceModel{D, W},
) where {
    T <: PSI.VariableValueParameter,
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: PSI.AbstractDeviceFormulation,
} where {D <: PSY.HybridSystem}
    PSI.add_parameters!(container, T(), devices, model)
    return
end


function PSI.add_parameters!(
    container::PSI.OptimizationContainer,
    ::T,
    devices::U,
    model::PSI.DeviceModel{D, W},
) where {
    T <: PSI.ActivePowerTimeSeriesParameter,
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: Union{HybridProbablisticDispatch,HybridProbablisticCostDispatch},
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


# function PSI.add_parameters!(
#     container::PSI.OptimizationContainer,
#     ::T,
#     devices::U,
#     model::PSI.DeviceModel{D, W},
# ) where {
#     T <: TotalEnergyParameter,
#     U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
#     W <: PSI.AbstractHybridFormulation,
# } where {D <: PSY.HybridSystem}
#     ts_type = PSI.PSI.get_default_time_series_type(container)
#     if !(ts_type <: Union{PSY.AbstractDeterministic, PSY.StaticTimeSeries})
#         error("add_parameters! for TimeSeriesParameter is not compatible with $ts_type")
#     end
#     time_steps = PSI.get_time_steps(container)
#     names = [PSY.get_name(d) for d in devices]
#     ts_name = PSI.get_time_series_names(model)[T]
#     time_series_mult_id = PSI.create_time_series_multiplier_index(model, T)
#     @debug "adding" T ts_name ts_type time_series_mult_id _group =
#         PSI.LOG_GROUP_OPTIMIZATION_CONTAINER
#     parameter_container =
#         PSI.add_param_container!(container, T(), D, ts_type, ts_name, names)
#     PSI.set_time_series_multiplier_id!(PSI.get_attributes(parameter_container), time_series_mult_id)
#     jump_model = PSI.get_jump_model(container)
#     for d in devices
#         name = PSY.get_name(d)
#         ts_vector = PSI.get_time_series(container, d, T())
#         multiplier = PSI.get_multiplier_value(T(), d, W())

#         PSI.set_parameter!(
#             parameter_container,
#             jump_model,
#             ts_vector[1],
#             multiplier,
#             name,
#         )
#     end
#     return
# end


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
                ts_vector[t],
                multiplier,
                name,
                r,
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
    T <: CalculatedCostParameter,
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
        PSI.add_param_container!(container, T(), D, ts_type, ts_name, names, 1:6, time_steps)
    PSI.set_time_series_multiplier_id!(PSI.get_attributes(parameter_container), time_series_mult_id)
    jump_model = PSI.get_jump_model(container)

    for d in devices
        name = PSY.get_name(d)
        ts_vector = PSI.get_time_series(container, d, T())
        multiplier = PSI.get_multiplier_value(T(), d, W())
        for t in time_steps
            i = 1
            for cost_pairs in ts_vector[t]
                for c in cost_pairs
                    PSI.set_parameter!(
                        parameter_container,
                        jump_model,
                        c,
                        multiplier,
                        name,
                        i,
                        t,
                    )
                    i += 1
                end
            end
        end
    end
    return
end

function PSI.add_parameters!(
    container::PSI.OptimizationContainer,
    ::T,
    devices::V,
    model::PSI.DeviceModel{D, W},
) where {
    T <: PowerScheduledParameter,
    V <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: PSI.AbstractDeviceFormulation,
} where {D <: PSY.Component}
    @debug "adding" T D V _group = PSI.LOG_GROUP_OPTIMIZATION_CONTAINER

    # We do this to handle cases where the same parameter is also added as a Feedforward.
    # When the OnStatusParameter is added without a feedforward it takes a Float value.
    # This is used to handle the special case of compact formulations.

    names = [PSY.get_name(device) for device in devices]
    time_steps = PSI.get_time_steps(container)
    parameter_container = PSI.add_param_container!(
        container,
        T(),
        D,
        PSI.VariableKey(PSI.ActivePowerVariable, D),
        names,
        time_steps,
    )
    jump_model = PSI.get_jump_model(container)

    for d in devices
        name = PSY.get_name(d)
        for t in time_steps
            PSI.set_parameter!(
                parameter_container,
                jump_model,
                PSI.get_initial_parameter_value(T(), d, W()),
                PSI.get_parameter_multiplier(T(), d, W()),
                name,
                t,
            )
        end
    end
    return
end

# function PSI.add_parameters!(
#     container::PSI.OptimizationContainer,
#     ::Type{T},
#     key::PSI.ConstraintKey{U, D},
#     model::PSI.NetworkModel{W},
# ) where {
#     T <: PSI.ConstraintValueParameter,
#     U <: PSI.ConstraintType,
#     W <: PSI.PM.AbstractPowerModel
#     D <: PSY.System,
# }
#     PSI.add_parameters!(container, T(), key, model)
#     return
# end

# function PSI.add_parameters!(
#     container::PSI.OptimizationContainer,
#     ::Type{T},
#     key::PSI.ConstraintKey{U, D},
#     model::PSI.NetworkModel{W},
#     devices::V,
# ) where {
#     T <: PSI.ConstraintValueParameter,
#     U <: PSI.ConstraintType,
#     D <: PSY.Component,
#     W <: PSI.PM.AbstractPowerModel,
# }
#     PSI.add_parameters!(container, T(), key, model, devices)
#     return
# end

# function PSI.add_parameters!(
#     container::PSI.OptimizationContainer,
#     ::T,
#     key::ConstraintKey{U, D},
#     model::PSI.NetworkModel{W},
# ) where {
#     T <: ConstraintValueParameter,
#     U <: PSI.ConstraintType,
#     D <: PSY.System,
#     W <: PSI.PM.AbstractPowerModel
# } where {D <: PSY.Component}
#     @debug "adding" T D V _group = PSI.LOG_GROUP_OPTIMIZATION_CONTAINER

#     # We do this to handle cases where the same parameter is also added as a Feedforward.
#     # When the OnStatusParameter is added without a feedforward it takes a Float value.
#     # This is used to handle the special case of compact formulations.
#     time_steps = get_time_steps(container)
#     variable = add_variable_container!(container, T(), PSY.System, time_steps)

#     parameter_container = PSI.add_param_container!(
#         container,
#         T(),
#         D,
#         PSI.ConstraintKey(PSI.CopperPlateBalanceConstraint, PSY.System),
#         time_steps,
#     )
#     jump_model = PSI.get_jump_model(container)
#     devs = PSI.encode_key_as_string(PSI.ConstraintKey(PSI.CopperPlateBalanceConstraint, PSY.System))
#     # for d in devs
#     #     name = PSY.get_name(d)
#         for t in time_steps
#             PSI.set_parameter!(
#                 parameter_container,
#                 jump_model,
#                 PSI.get_initial_parameter_value(T(), d, W()),
#                 PSI.get_parameter_multiplier(T(), d, W()),
#                 name,
#                 t,
#             )
#         end
#     # end
#     return
# end
