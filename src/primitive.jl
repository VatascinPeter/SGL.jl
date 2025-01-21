using StaticArrays
using LinearAlgebra
using ColorTypes

abstract type Primitive{T<:AbstractFloat} end

# should not be mutable
struct Material{T<:AbstractFloat}
    rgb::RGB{T}

    kd::T
    ks::T
    shine::T
    T::T
    ior::T
end

# should not be mutable
struct Triangle{T<:AbstractFloat} <: Primitive{T}
    v1::SVector{3, T}
    v2::SVector{3, T}
    v3::SVector{3, T}
    # normalized
    normal::SVector{3, T}
    # v2 - v1
    e1::SVector{3, T}
    # v3 - v1
    e2::SVector{3, T}
    mat::Material{T}
end

# should not be mutable
struct Sphere{T<:AbstractFloat} <: Primitive{T}
    centre::SVector{3, T}
    radius::T
    mat::Material{T}
end

# should not be mutable
struct PointLight{T<:AbstractFloat}
    position::SVector{3, T}
    rgb::RGB{T}
end

# should not be mutable
struct Ray{T<:AbstractFloat}
    origin::SVector{3, T}

    # normalized
    direction::SVector{3, T}
end

test_print(::Triangle) = println("This is a triangle")

test_print(::Sphere) = println("This is a sphere")

function get_material(primitive::Sphere{T}) where {T<:AbstractFloat}
    return primitive.mat
end

function get_material(primitive::Triangle{T}) where {T<:AbstractFloat}
    return primitive.mat
end

# returns float t - ray.origin + t * ray.direction = intersection point
function find_intersection(r::Ray, s::Sphere{T}) where T <: AbstractFloat
    dst = r.origin - s.centre
    b = dot(dst, r.direction)
    c = dot(dst, dst) - s.radius * s.radius
    d = b * b - c
    res = -one(T)

    if d > 0
        sqrt_d = sqrt(d)
        res = - b - sqrt_d
        if res < 0
            res = -b + sqrt_d
        end
    end

    res
end

function find_intersection(r::Ray, t::Triangle{T}) where T <: AbstractFloat
    res = -one(T)
    s1 = cross(r.direction, t.e2)
    divisor = dot(s1, t.e1)
    if divisor != 0
        inverse_divisor = one(T) / divisor
        d = r.origin - t.v1
        b1 = dot(d, s1) * inverse_divisor
        if b1 >= 0 && b1 <= 1
            s2 = cross(d, t.e1)
            b2 = dot(r.direction, s2) * inverse_divisor
            if b2 >= 0 && b1 + b2 <= 1
                res = dot(t.e2, s2) * inverse_divisor
            end
        end
    end
    res
end

function get_normal(t::Triangle, ::Any)
    t.normal
end

function get_normal(s::Sphere{T}, point::SVector{3, T}) where T <: AbstractFloat
    normalize(point - s.centre)
end
