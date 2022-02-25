function PSI.get_column_names(
    ::PSI.OptimizationContainerKey,
    array::DenseAxisArray{T, 3, K},
) where {T, K }
    return string.(axes(array)[1])
end
