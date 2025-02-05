include("data_structure.jl")

mutable struct Scene{T<:AbstractFloat}
    width::Int
    height::Int
    primitives::DataStructure
    lights::Vector{PointLight}
    current_material::Material
    camera_fov_tan::T
    camera_to_world::SMatrix{4, 4, T}
    background_color::RGB{T}
    shadow_epsilon::T
    recursion_depth::Int
    antialiasing::Bool
    aa_max_color_diff::T
    aa_sqrt_rays::Int
end

# create a scene that will render images in resolution (width x height)
create_scene(width::Int, height::Int) = Scene(width, height, Naive(Vector{Primitive}(undef, 0)), Vector{PointLight}(undef, 0),
Material{Float64}(RGB(0.0, 0.0, 0.0), 0.0, 0.0, 0.0, 0.0, 0.0), 
1.0, SMatrix{4, 4, Float64}(1.0, 0.0, 0.0, 0.0,
                             0.0, 1.0, 0.0, 0.0,
                             0.0, 0.0, 1.0, 0.0,
                             0.0, 0.0 ,0.0, 1.0), 
                             RGB{Float64}(0.0, 0.0, 0.0),
                             0.0001,
                             8,
                             false, 0.4, 2)

# defines material that will be applied to all primitives added until next set_material call
function set_material(s::Scene, r::T, g::T, b::T, kd::T, ks::T, shine::T, t::T, ior::T) where T <: AbstractFloat
    s.current_material = Material{T}(RGB(r, g, b), kd, ks, shine, t, ior)
end

function set_background_color(s::Scene, r::T, g::T, b::T) where T <: AbstractFloat
    s.background_color = RGB(r, g, b)
end

function set_shadow_epsilon(s::Scene, e::T) where T <: AbstractFloat
    s.shadow_epsilon = e
end

function set_recursion_depth(s::Scene, r::Int)
    s.recursion_depth = r
end

function set_antialiasing(s::Scene, diff::T, sqrt_rays::Int) where T <: AbstractFloat
    s.antialiasing = true
    s.aa_max_color_diff = diff
    s.aa_sqrt_rays = sqrt_rays
end

function disable_antialiasing(s::Scene)
    s.antialiasing = false
end

# adds a triangle to the scene
function add_triangle(s::Scene, x1::T, y1::T, z1::T, x2::T, y2::T, z2::T, x3::T, y3::T, z3::T) where T <: AbstractFloat
    v1 = SVector{3, T}(x1, y1, z1)
    v2 = SVector{3, T}(x2, y2, z2)
    v3 = SVector{3, T}(x3, y3, z3)

    e1 = v2 - v1
    e2 = v3 - v1
    normal = normalize(cross(e1, e2))

    add_primitive(s.primitives, Triangle{T}(v1, v2, v3, normal, e1, e2, s.current_material))
end

# adds a sphere to the scene
function add_sphere(s::Scene, x::T, y::T, z::T, r::T) where T <: AbstractFloat
    centre = SVector{3, T}(x, y, z)

    add_primitive(s.primitives, Sphere{T}(centre, r, s.current_material))
end

function add_light(s::Scene, x::T, y::T, z::T, r::T, g::T, b::T) where T <: AbstractFloat
    push!(s.lights, PointLight{T}(SVector{3, T}(x, y, z), RGB(r, g, b)))
end

function add_light(s::Scene, x::T, y::T, z::T) where T <: AbstractFloat
    push!(s.lights, PointLight{T}(SVector{3, T}(x, y, z), RGB(1.0, 1.0, 1.0)))
end

# specify the camera using the camera origin, look at vector, up vector, and field of view angle (0, 90)
function specify_camera(s::Scene, from_x::T, from_y::T, from_z::T, 
    at_x::T, at_y::T, at_z::T, 
    up_x::T, up_y::T, up_z::T, fov::T) where T <: AbstractFloat
    
    if fov >= 180 || fov <= 0
        error("Field of view angle (fov) ∉ (0°, 180°).")
    end

    s.camera_fov_tan = tand(fov / 2)

    # calculate camera-to-world transformation matrix
    f = SVector{3, T}(at_x, at_y, at_z) - SVector{3, T}(from_x, from_y, from_z)

    if norm(f) > 0.0
        f = normalize(f)
    end

    r = cross(SVector{3, T}(up_x, up_y, up_z), f)

    if norm(r) > 0.0
        r = normalize(r)
    end

    u = cross(f, r)

    s.camera_to_world = @SMatrix [r[1] u[1] -f[1] from_x; r[2] u[2] -f[2] from_y; r[3] u[3] -f[3] from_z; zero(T) zero(T) zero(T) one(T)]
    # s.camera_to_world = SMatrix{4, 4, T}(r[1], u[1], -f[1], from_x,
    #                                      r[2], u[2], -f[2], from_y,
    #                                      r[3], u[3], -f[3], from_z,
    #                                      zero(T), zero(T), zero(T), one(T))
end

# removes all primitives from the scene (resets camera?)
function clear_scene(s::Scene)
    clear_structure(s.primitives)
    s.lights = Vector{PointLight}(undef, 0)
end


