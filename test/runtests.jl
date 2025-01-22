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
    ray = SGL.Ray{Float64}(SVector{3, Float64}(0.0, 0.0, -1.0), normalize(SVector{3, Float64}(1.0, 0.0, 2.0)))

    @test SGL.find_intersection(ray, triangle) ≈ sqrt(1.25) atol=0.001

    sphere = SGL.Sphere{Float64}(SVector{3, Float64}(0.5, 1.0, 0.0), 1.0, dummy_mat)
    @test SGL.find_intersection(ray, sphere) ≈ sqrt(1.25) atol=0.001
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


