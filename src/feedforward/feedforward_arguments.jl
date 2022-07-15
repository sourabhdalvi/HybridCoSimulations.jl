function add_feedforward_arguments!(
    container::OptimizationContainer,
    model::NetworkModel,
    devices::IS.FlattenIteratorWrapper{T},
    ff::PowerPriceFeedforward,
) where {T <: PSY.Component}
    parameter_type = get_default_parameter_type(ff, T)
    source_key = get_optimization_container_key(ff)
    add_parameters!(container, parameter_type, source_key, model, devices)
    return
end
