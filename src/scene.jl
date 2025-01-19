
include("primitive.jl")

mutable struct Scene{T<:AbstractFloat}
    width::Int
    height::Int
    primitives::Vector{Primitive}
    lights::Vector{PointLight}
    current_material::Material
    camera_fov_tan::T
    camera_to_world::SMatrix{4, 4, T}
end

# create a scene that will render images in resolution (width x height)
create_scene(width::Int, height::Int) = Scene(width, height, Vector{Primitive}(undef, 0), Vector{PointLight}(undef, 0),
Material{Float64}(SVector{3, Float64}(0.0, 0.0, 0.0), 0.0, 0.0, 0.0, 0.0, 0.0), 
1.0, SMatrix{4, 4, Float64}(1.0, 0.0, 0.0, 0.0,
                             0.0, 1.0, 0.0, 0.0,
                             0.0, 0.0, 1.0, 0.0,
                             0.0, 0.0 ,0.0, 1.0))

# defines material that will be applied to all primitives added until next set_material call
function set_material(s::Scene, r::T, g::T, b::T, kd::T, ks::T, shine::T, t::T, ior::T) where T <: AbstractFloat
    s.current_material = Material{T}(SVector{3, T}(r, g, b), kd, ks, shine, t, ior)
end

# adds a triangle to the scene
function add_triangle(s::Scene, x1::T, y1::T, z1::T, x2::T, y2::T, z2::T, x3::T, y3::T, z3::T) where T <: AbstractFloat
    
    println("AAAAAAAAA")
    v1 = SVector{3, T}(x1, y1, z1)
    v2 = SVector{3, T}(x2, y2, z2)
    v3 = SVector{3, T}(x3, y3, z3)

    e1 = v2 - v1
    e2 = v3 - v1
    normal = normalize(cross(e1, e2))

    push!(s.primitives, Triangle{T}(v1, v2, v3, normal, e1, e2, s.current_material))
end

# adds a sphere to the scene
function add_sphere(s::Scene, x::T, y::T, z::T, r::T) where T <: AbstractFloat
    centre = SVector{3, T}(x, y, z)

    push!(s.primitives, Sphere{T}(centre, r, s.current_material))
end

# specify the camera using the camera origin, look at vector, up vector, and field of view angle (0, 90)
function specify_camera(s::Scene, from_x::T, from_y::T, from_z::T, 
    at_x::T, at_y::T, at_z::T, 
    up_x::T, up_y::T, up_z::T, fov::T) where T <: AbstractFloat
    
    if fov >= 90 || fov <= 0
        error("Field of view angle (fov) ∉ (0°, 90°).")
    end

    s.camera_fov = fov

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

# returns an image
function ray_trace(s::Scene)
    result = MArray{Tuple{s.width, s.height, 3}, Float64}(undef)
    camera_origin = SVector{3, Float64}(s.camera_to_world[1:3, 4])
    for i in 1:1:s.width
        for j in 1:1:s.height
            # calculate ray
            pixel_camera = SVector{4, Float64}((2.0 * (i - 0.5) - s.width) * s.camera_fov_tan / s.height, 
            (1.0 - 2.0 * (j - 0.5) / s.height) * s.camera_fov_tan, 
            -1.0, 
            1.0)
            ray_direction = SVector{3, Float64}(normalize((s.camera_to_world * pixel_camera)[1:3] - camera_origin))
            ray = Ray(camera_origin, ray_direction)

            # TODO: make this a function and make it modular
            # find closest intersection

            best_t = Inf64
            best_material = s.current_material
            for prim in s.primitives
                t = find_intersection(ray, prim)
                if (t > 0.0 && t < best_t)
                    best_t = t
                    best_material = get_material(prim)
                end
            end

            # calculate color
            # simple, no lighting
            result[i, j, :] .= best_material.rgb

            # write color
        end
    end

    # post processing
    result
end

# removes all primitives from the scene (resets camera?)
function clear_scene(s::Scene)
    s.primitives = Vector{Primitive}(undef, 0)
    s.lights = Vector{PointLight}(undef, 0)
end


