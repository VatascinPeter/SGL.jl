# SGL [![Build Status](https://github.com/VatascinPeter/SGL.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/VatascinPeter/SGL.jl/actions/workflows/CI.yml?query=branch%3Amaster)

## Simple Graphics Library

A simple ray tracing library which let's the user define a scene using triangles, spheres and point lights. The camera is defined by from, at, and up vectors, as well as by a field of view angle. The color is determined using the Phong lighting with shadows, refractions and reflections. A simple NFF format parser is also implemented. 

## Syntax

**create_scene(width, height)** - returns a Scene object with specified dimensions.

**specify_camera(scene, from..., at..., up..., fov)** - defines the camera for ray tracing by from, at, and up vectors (3 coordinates each), and a field of view angle (0, 180) in degrees.

**set_background_color(scene, red, green, blue)** - defines a color [0, 1] returned if a ray does not intersect any object.

**set_material(scene, red, green, blue, diffuse, specular, shine, T, index_of_refraction)** - defines a material for all following primitive definitions until another set_material is called.

**add_triangle(scene, vertices...)** - a triangle is added to the scene defined by 3 vertices, each having 3 coordinates.

**add_sphere(scene, centre..., radius)** - a sphere is added to the scene, defined by it's centre (3 coordinates) and a radius.

**add_light(scene, position..., color...)** - a point light is added to the scene, defined by it's position (3 coordinates) and color (r, g, b).

**ray_trace(scene)** - performs ray tracing to get an image represented by a Matrix{RGB{Float64}}(height, width).

**set_shadow_epsilon(scene, epsilon)** - defines relative distance from light source and ray intersection, where an occlusion is not considered (to prevent self occluding). Default value is 0.0004.

**set_recursion_depth(scene, depth)** - defines how many times light can be reflected or refracted.

**set_antialiasing(scene, diff, sqrt_rays)** - enables adaptive antialiasing. If there is a difference in color between neighbouring pixels larger than diff, (sqrt_rays x sqrt_rays) rays are cast from the pixel and the average of returning colors is used for the given pixel.

**disable_antialiasing(scene)** - disables antialiasing

**clear_scene(scene)** - removes all primitives and lights

## Examples

To see examples of usage, see scripts inside the folder "scripts" for inspiration. The "example.jl" script creates a cornell box with a reflective and refractive sphere. The "parse_nff.jl" parses a NFF file and creates a ray traced image. Note that all definitions must be in one line in the NFF file, except for camera definition.

