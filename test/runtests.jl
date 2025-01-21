using Revise
using SGL
using Test

@testset "SGL.jl" begin
    # Write your tests here.
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
