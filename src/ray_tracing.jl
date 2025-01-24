include("scene.jl")

using Base.Threads

# returns an image
function ray_trace(s::Scene)
    #result = MArray{Tuple{s.width, s.height, 3}, Float64}(undef)
    result = Matrix{RGB{Float64}}(undef, s.height, s.width)

    if is_empty(s.primitives)
        return result
    end

    camera_origin = SVector{3, Float64}(s.camera_to_world[1:3, 4])

    Threads.@threads for i in 1:1:s.width
        for j in 1:1:s.height
            # calculate ray
            pixel_camera = SVector{4, Float64}((2.0 * (i - 0.5) - s.width) * s.camera_fov_tan / s.height, 
            (1.0 - 2.0 * (j - 0.5) / s.height) * s.camera_fov_tan, 
            -1.0, 
            1.0)
            ray_direction = SVector{3, Float64}(normalize((s.camera_to_world * pixel_camera)[1:3] - camera_origin))
            ray = Ray(camera_origin, ray_direction)

            result[j, s.width - i + 1] = get_ray_color(s, ray, s.recursion_depth)
        end
    end

    # post processing
    if s.antialiasing
        return run_antialiasing(s, result)
    end
    result
end

function get_ray_color(s::Scene, ray::Ray{T}, recur::Int) where T <: AbstractFloat
    best_t, best_prim = get_closest_intersection(s.primitives, ray)

    # calculate color
    if best_t < Inf64
        # return best_prim.mat.rgb
        return calculate_color_phong(s, get_prim(s.primitives, best_prim), ray, best_t, recur)
    else
        return s.background_color
    end
end

function calculate_color_phong(s::Scene{T}, prim::Primitive{T}, ray::Ray{T}, t::T, recur::Int) where T <: AbstractFloat
    rgb = SVector{3, T}(0.0, 0.0, 0.0)
    intersection_position = SVector{3, T}(ray.direction * t + ray.origin)
    prim_mat = get_material(prim)
    prim_col = SVector{3, T}(prim_mat.rgb.r, prim_mat.rgb.g, prim_mat.rgb.b)
    prim_normal = get_normal(prim, intersection_position)
    for light in s.lights
        light_pos = SVector{3, T}(light.position[1], light.position[2], light.position[3])
        light_dir = SVector{3, T}(normalize(light_pos - intersection_position))
        if is_obscured(s, Ray(intersection_position, light_dir), norm(light.position - intersection_position))
            continue
        end
        light_col = SVector{3, T}(light.rgb.r, light.rgb.g, light.rgb.b)
        diffuse = prim_mat.kd * light_col .* prim_col * max(dot(prim_normal, light_dir), 0.0)

        reflect_dir = normalize(-light_dir - 2.0 * dot(-light_dir, prim_normal) .* prim_normal)
        specular = prim_mat.ks * light_col * (max(dot(-ray.direction, reflect_dir), 0.0) ^ prim_mat.shine)

        rgb += SVector{3, T}(diffuse + specular)
    end

    if recur > 0
        # reflection
        if prim_mat.T != 1.0 && prim_mat.ks != 0.0
            reflect_dir = normalize(ray.direction - 2.0 * dot(ray.direction, prim_normal) * prim_normal)
            reflect_col = get_ray_color(s, Ray(intersection_position + 0.01 * (-ray.direction), reflect_dir), recur - 1)
            rgb += SVector{3, T}((1.0 - prim_mat.T) * prim_mat.ks * SVector{3, T}(reflect_col.r, reflect_col.g, reflect_col.b))
        end

        # refraction
        if prim_mat.T != 0.0
            VdotN = dot(ray.direction, prim_normal)
            gamma = prim_mat.ior
            neg_normal = -prim_normal

            if VdotN < 0.0
                gamma = 1 / gamma
                VdotN = -VdotN
                neg_normal = prim_normal
            end

            sqterm = 1.0 - gamma * gamma * (1.0 - VdotN * VdotN)

            if sqterm > 0.0
                sqterm = sqrt(sqterm)

                refract_dir = normalize((sqterm * (-neg_normal)) - gamma * ((VdotN * (-neg_normal)) - ray.direction))
                refract_col = get_ray_color(s, Ray(intersection_position - s.shadow_epsilon * neg_normal, refract_dir), recur - 1)
                rgb += SVector{3, T}(prim_mat.T * SVector{3, T}(refract_col.r, refract_col.g, refract_col.b))
            end
        end
    end

    return RGB(min(rgb[1], 1.0), min(rgb[2], 1.0), min(rgb[3], 1.0))
end

function is_obscured(s::Scene, ray::Ray{T}, dist::T) where T <: AbstractFloat
    is_obscured(s.primitives, ray, dist, s.shadow_epsilon)
end

function run_antialiasing(s::Scene, original::Matrix{RGB{Float64}})
    result = Matrix{RGB{Float64}}(undef, s.height, s.width)
    num_rays = 1.0 / (s.aa_sqrt_rays * s.aa_sqrt_rays)
    fraction = 1.0 / s.aa_sqrt_rays
    fraction2 = 1.0 / (2.0 * s.aa_sqrt_rays)
    inv_width = 1.0 / s.width
    inv_height = 1.0 / s.height

    for i in 1:1:s.height
        for j in 1:1:s.width
            if (j > 1 && compare_color(original[i, j], original[i, j - 1], s.aa_max_color_diff)) ||
                (j < s.width && compare_color(original[i, j], original[i, j + 1], s.aa_max_color_diff)) ||
                (i > 1 && compare_color(original[i, j], original[i - 1, j], s.aa_max_color_diff)) ||
                (i < s.height && compare_color(original[i, j], original[i + 1, j], s.aa_max_color_diff))

                r = 0.0
                g = 0.0
                b = 0.0
                for u in 1:1:s.aa_sqrt_rays
                    for v in 1:1:s.aa_sqrt_rays
                        pixel_camera = SVector{4, Float64}((2.0 * (s.width - j + 1 - fraction2 - (u - 1) * fraction) - s.width) * s.camera_fov_tan * inv_height,
                        (1.0 - 2.0 * (i - fraction2 - (v - 1) * fraction) * inv_height) * s.camera_fov_tan,
                        -1.0, 1.0)
                        ray_direction = SVector{3, Float64}(normalize((s.camera_to_world * pixel_camera)[1:3] - s.camera_to_world[1:3, 4]))
                        ray = Ray(SVector{3, Float64}(s.camera_to_world[1:3, 4]), ray_direction)

                        color = get_ray_color(s, ray, s.recursion_depth)
                        r += color.r
                        g += color.g
                        b += color.b
                    end
                end
                
                result[i, j] = RGB{Float64}(r * num_rays, g * num_rays, b * num_rays)
            else
                result[i, j] = original[i, j]
            end
        end
    end

    return result
end

function compare_color(c1::RGB{Float64}, c2::RGB{Float64}, diff::T) where T <: AbstractFloat
    return abs(c1.r - c2.r) + abs(c1.g - c2.g) + abs(c1.b - c2.b) > diff
end
