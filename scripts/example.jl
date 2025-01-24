using Revise
using SGL

# for image conversion
using ColorTypes, Images, FileIO, StaticArrays, InteractiveUtils

Revise.revise()

println("Starting")
s = SGL.create_scene(600, 400)
SGL.specify_camera(s, 275.0, 275.0, -800.0, 275.0, 275.0, 0.0, 0.0, 1.0, 0.0, 40.0)

SGL.set_background_color(s, 0.0, 0.0, 0.0)
SGL.set_antialiasing(s, 0.4, 4)
SGL.add_light(s, 275.0, 549.0, 0.0, 1.0, 1.0, 1.0)

# add light sources
SGL.set_material(s, 0.2, 0.8, 0.2, 1.0, 0.0, 0.0, 0.0, 1.0)

# maybe change order
SGL.add_triangle(s, 0.0, 0.0, 550.0, 0.0, 0.0, 0.0, 0.0, 550.0, 0.0)
SGL.add_triangle(s, 0.0, 0.0, 550.0, 0.0, 550.0, 0.0, 0.0, 550.0, 550.0)

SGL.set_material(s, 0.8, 0.2, 0.2, 1.0, 0.0, 0.0, 0.0, 1.0)

# maybe change order
SGL.add_triangle(s, 550.0, 0.0, 0.0, 550.0, 0.0, 550.0, 550.0, 550.0, 550.0)
SGL.add_triangle(s, 550.0, 0.0, 0.0, 550.0, 550.0, 550.0, 550.0, 550.0, 0.0)

SGL.set_material(s, 0.7, 0.7, 0.7, 1.0, 0.0, 0.0, 0.0, 1.0)

# maybe change order
SGL.add_triangle(s, 550.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 550.0)
SGL.add_triangle(s, 550.0, 0.0, 550.0, 550.0, 0.0, 0.0, 0.0, 0.0, 550.0)

# maybe change order
SGL.add_triangle(s, 550.0, 550.0, 0.0, 0.0, 550.0, 550.0, 0.0, 550.0, 0.0)
SGL.add_triangle(s, 550.0, 550.0, 550.0, 0.0, 550.0, 550.0, 550.0, 550.0, 0.0)

SGL.add_triangle(s, 550.0, 0.0, 550.0, 0.0, 0.0, 550.0, 0.0, 550.0, 550.0)
SGL.add_triangle(s, 550.0, 0.0, 550.0, 0.0, 550.0, 550.0, 550.0, 550.0, 550.0)

SGL.set_material(s, 0.8, 0.7, 1.0, 0.1, 0.8, 60.0, 0.0, 1.0)

SGL.add_sphere(s, 420.0, 120.0, 300.0, 120.0)

SGL.set_material(s, 1.0, 1.0, 1.0, 0.0, 0.0, 60.0, 0.9, 1.6)

SGL.add_sphere(s, 170.0, 100.0, 150.0, 100.0)

ray1 = SGL.Ray{Float64}(SVector{3, Float64}(275.0, 275.0, -800.0), SVector{3, Float64}(0.0, 0.0, 1.0))
# @which SGL.find_intersection(ray1, s.primitives.primitives[end])
#@code_warntype SGL.calculate_color_phong(s, SGL.get_prim(s.primitives, 1), ray1, 850.0, 5)
println("RayTracing")
@time array_image = SGL.ray_trace(s)
println("Reformatting")

image = colorview(RGB, array_image)

println("Saving")
# Save the resulting image to a PNG file
save("example_output.png", image)
