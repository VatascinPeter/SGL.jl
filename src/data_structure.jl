include("primitive.jl")

abstract type DataStructure end

struct Naive <: DataStructure
    primitives::Vector{Primitive}
end

function add_primitive(n::Naive, p::Primitive)
    push!(n.primitives, p)
end

function clear_structure(n::Naive)
    n.primitives = Vector{Primitive}(undef, 0)
end

function is_empty(n::Naive)
    isempty(n.primitives)
end

function get_closest_intersection(n::Naive, ray::Ray{Float64})
    best_t = Inf64
    best_prim = n.primitives[1]
    t = Inf64
    for prim in n.primitives
        t = find_intersection(ray, prim)
        if (t > 0.0 && t < best_t)
            best_t = t
            best_prim = prim
        end
    end
    return best_t, best_prim
end

function is_obscured(n::Naive, ray::Ray, dist::T, shadow_epsilon::T) where T <: AbstractFloat
    epsilon = shadow_epsilon * dist
    t = Inf64
    for prim in n.primitives
        t = find_intersection(ray, prim)
        if t > epsilon && t < dist - epsilon
            return true
        end
    end

    return false
end
