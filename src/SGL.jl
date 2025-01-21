module SGL

# Export:
# new_scene(width, height), add_triangle, add_sphere, add_point_light, camera, ray_trace, (anti_aliasing, lighting_model
# secondary rays), reflection/refraction recursion depth (base 0)

export Scene
export create_scene, set_background_color, set_material, set_shadow_epsilon
export set_recursion_depth, set_antialiasing, disable_antialiasing, add_triangle
export add_sphere, add_light, specify_camera, clear_scene, ray_trace

include("ray_tracing.jl")

end
