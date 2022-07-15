
struct PowerPriceFeedforward <: AbstractAffectFeedforward
    optimization_container_key::OptimizationContainerKey
    function PowerPriceFeedforward(;
        component_type::Type{<:PSY.Component},
        source::Type{T},
        meta=CONTAINER_KEY_EMPTY_META,
    ) where {T}
        new(
            get_optimization_container_key(T(), component_type, meta),
        )
    end
end

get_default_parameter_type(::PowerPriceFeedforward, _) = PowerPriceParameter()
get_optimization_container_key(ff::PowerPriceFeedforward) = ff.optimization_container_key
