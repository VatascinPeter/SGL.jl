module SGL

export Scene
export create_scene, set_background_color, set_material, set_shadow_epsilon
export set_recursion_depth, set_antialiasing, disable_antialiasing, add_triangle
export add_sphere, add_light, specify_camera, clear_scene, ray_trace

include("ray_tracing.jl")

end
