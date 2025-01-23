using Revise
using SGL
using Test
using StaticArrays
using LinearAlgebra
using ColorTypes

@testset "edge intersections" begin
    v1 = SVector{3, Float64}(0.0, 0.0, 0.0)
    v2 = SVector{3, Float64}(0.5, 1.0, 0.0)
    v3 = SVector{3, Float64}(1.0, 0.0, 0.0)

    e1 = v2 - v1
    e2 = v3 - v1
    normal = normalize(cross(e1, e2))

    dummy_mat = SGL.Material{Float64}(RGB(0.0, 0.0, 0.0), 0.0, 0.0, 0.0, 0.0, 0.0)
    triangle = SGL.Triangle{Float64}(v1, v2, v3, normal, e1, e2, dummy_mat)

    ray1 = SGL.Ray{Float64}(SVector{3, Float64}(0.0, 0.0, -1.0), normalize(SVector{3, Float64}(1.0, 0.0, 2.0)))

    sphere = SGL.Sphere{Float64}(SVector{3, Float64}(0.5, 1.0, 0.0), 1.0, dummy_mat)

    # testing for edge intersection
    @test SGL.find_intersection(ray1, triangle) ≈ sqrt(1.25) atol=0.001
    @test SGL.find_intersection(ray1, sphere) ≈ sqrt(1.25) atol=0.001

    ray2 = SGL.Ray{Float64}(SVector{3, Float64}(0.0, 0.0, -1.0), normalize(SVector{3, Float64}(0.0, 0.0, 1.0)))

    # triangle vertex intersection
    @test SGL.find_intersection(ray2, triangle) ≈ 1.0 atol=0.0001

    ray3 = SGL.Ray{Float64}(SVector{3, Float64}(0.5, 0.5, 0.0), normalize(SVector{3, Float64}(0.1, 0.1, 0.1)))

    # ray starts on the surface
    @test SGL.find_intersection(ray3, triangle) ≈ 0.0 atol=0.0001

    ray4 = SGL.Ray{Float64}(SVector{3, Float64}(0.5, 0.5, -3.0), SVector{3, Float64}(0.0, 0.0, 1.0))

    # sphere returns closer intersection
    @test SGL.find_intersection(ray4, sphere) ≈ 3 - sqrt(3) / 2 atol=0.001

    ray5 = SGL.Ray{Float64}(SVector{3, Float64}(0.0, 0.5, 1.0), normalize(SVector{3, Float64}(1.0, 0.0, -2.0)))

    println("TRIANGLE BACKFACE: ", dot(triangle.normal, ray5.direction))
    # triangle backface culling
    @test SGL.find_intersection(ray5, triangle) == -1.0

    ray6 = SGL.Ray{Float64}(SVector{3, Float64}(0.5, 1.0, 0.0), SVector{3, Float64}(0.0, 0.0, 1.0))

    # sphere backface culling
    @test SGL.find_intersection(ray6, sphere) == -1.0

    ray7 = SGL.Ray{Float64}(SVector{3, Float64}(0.5, -0.1, -2), SVector{3, Float64}(0.0, 0.0, 1.0))

    # ray misses
    @test SGL.find_intersection(ray7, triangle) < 0.0
    @test SGL.find_intersection(ray7, sphere) < 0.0
end

@testset "perfect diffuse and specular surfaces" begin
    s = create_scene(10, 10)
    set_material(s, 0.5, 0.7, 0.3, 1.0, 0.0, 1.0, 0.0, 1.0)
    add_triangle(s, 0.0, 0.0, 0.0, 0.5, 1.0, 0.0, 1.0, 0.0, 0.0)
    add_light(s, 0.5, 0.5, 1.0, 1.0, 1.0, 1.0)

    intersection = SVector{3, Float64}(0.5, 0.5, 0.0)
    origin1 = SVector{3, Float64}(0.0, 0.0, -5.0)
    origin2 = SVector{3, Float64}(5.0, 5.0, -2.0)

    ray1 = SGL.Ray{Float64}(origin1, normalize(intersection - origin1))
    ray2 = SGL.Ray{Float64}(origin2, normalize(intersection - origin2))

    # has the same color from different view angles
    @test SGL.get_ray_color(s, ray1, 3) ≈ SGL.get_ray_color(s, ray2, 3) atol=0.0001
    prev_color = SGL.get_ray_color(s, ray2, 3)
    set_material(s, 0.0, 0.0, 0.0, 0.0, 1.0, 1000.0, 0.0, 1.0)
    add_triangle(s, 0.0, 0.0, 2.0, 1.0, 0.0, 2.0, 0.5, 1.0, 2.0)

    ray3 = SGL.Ray{Float64}(SVector{3, Float64}(0.5, 0.5, 1.0), SVector{3, Float64}(0.0, 0.0, -1.0))
    # perfectly reflected light has the same color as diffuse
    @test SGL.get_ray_color(s, ray3, 3) ≈ prev_color atol=0.0001
end

@testset "antialiasing alignment" begin
    s = create_scene(600, 400)
    specify_camera(s, 275.0, 275.0, -800.0, 275.0, 275.0, 0.0, 0.0, 1.0, 0.0, 40.0)
    add_light(s, 275.0, 549.0, 0.0, 1.0, 1.0, 1.0)

    set_material(s, 0.2, 0.8, 0.2, 1.0, 0.0, 0.0, 0.0, 1.0)

    add_triangle(s, 0.0, 0.0, 550.0, 0.0, 0.0, 0.0, 0.0, 550.0, 0.0)
    add_triangle(s, 0.0, 0.0, 550.0, 0.0, 550.0, 0.0, 0.0, 550.0, 550.0)

    set_material(s, 0.8, 0.2, 0.2, 1.0, 0.0, 0.0, 0.0, 1.0)

    add_triangle(s, 550.0, 0.0, 0.0, 550.0, 0.0, 550.0, 550.0, 550.0, 550.0)
    add_triangle(s, 550.0, 0.0, 0.0, 550.0, 550.0, 550.0, 550.0, 550.0, 0.0)

    set_material(s, 0.7, 0.7, 0.7, 1.0, 0.0, 0.0, 0.0, 1.0)

    add_triangle(s, 550.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 550.0)
    add_triangle(s, 550.0, 0.0, 550.0, 550.0, 0.0, 0.0, 0.0, 0.0, 550.0)

    add_triangle(s, 550.0, 550.0, 0.0, 0.0, 550.0, 550.0, 0.0, 550.0, 0.0)
    add_triangle(s, 550.0, 550.0, 550.0, 0.0, 550.0, 550.0, 550.0, 550.0, 0.0)

    add_triangle(s, 550.0, 0.0, 550.0, 0.0, 0.0, 550.0, 0.0, 550.0, 550.0)
    add_triangle(s, 550.0, 0.0, 550.0, 0.0, 550.0, 550.0, 550.0, 550.0, 550.0)

    set_material(s, 0.8, 0.7, 1.0, 0.1, 0.8, 60.0, 0.0, 1.0)

    add_sphere(s, 420.0, 120.0, 300.0, 120.0)

    set_material(s, 1.0, 1.0, 1.0, 0.0, 0.0, 60.0, 0.9, 1.6)

    add_sphere(s, 170.0, 100.0, 150.0, 100.0)

    primary_image = ray_trace(s)
    set_antialiasing(s, 0.0, 1)
    secondary_image = ray_trace(s)
    @test primary_image == secondary_image
end


