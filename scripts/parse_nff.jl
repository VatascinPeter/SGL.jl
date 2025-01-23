using Revise
using SGL

using BenchmarkTools
using InteractiveUtils

# for image conversion
using ColorTypes, Images, FileIO

function parse_camera(line::String)
    words = split(line)

    if isempty(words) || startswith(words[1], "#") || startswith(words[1], "B")
        return
    end

    cmd = words[1]
    args = parse.(Float64, words[2:end])

    if cmd == "from"
        return :from, args...
    elseif cmd == "at"
        return :at, args...
    elseif cmd == "up"
        return :up, args...
    elseif cmd == "angle"
        return :fov, args...
    elseif cmd == "resolution"
        return :res, args...
    end
end

function parse_line(s::Scene, line::String)
    words = split(line)

    # ignore empty and comment lines
    if isempty(words) || startswith(words[1], "#") || startswith(words[1], "B")
        return
    end

    cmd = words[1]
    args = parse.(Float64, words[2:end])

    if cmd == "b"
        set_background_color(s, args...)
    elseif cmd == "v" || cmd == "from" || cmd == "at" || cmd == "up" || cmd == "angle" || cmd == "hither" || cmd == "resolution"
        # parsed elsewhere
    elseif cmd == "l"
        add_light(s, args...)
    elseif cmd == "f"
        set_material(s, args...)
    elseif cmd == "p"
        num_vertices = trunc(Int, args[1])
        if num_vertices < 3
            return
        end

        for i in 1:1:(num_vertices - 2)
            add_triangle(s, args[2], args[3], args[4], args[5 + (i - 1) * 3], args[6 + (i - 1) * 3], args[7 + (i - 1) * 3], args[8 + (i - 1) * 3], args[9 + (i - 1) * 3], args[10 + (i - 1) * 3])
        end
    elseif cmd == "s"
        add_sphere(s, args...)
    else
        println("Unknown command ", cmd)
    end
end

function raytrace_scene(file_name::String)
    file_path = "../data/" * file_name * ".nff"

    println("Parsing file " * file_name * ".nff")
    camera_specs = Vector{Float64}(undef, 12)
    open(file_path, "r") do io
        for line in eachline(io)
            res = parse_camera(line)
            if isnothing(res)
                continue
            end
    
            if res[1] == :from
                camera_specs[1] = res[2]
                camera_specs[2] = res[3]
                camera_specs[3] = res[4]
            elseif res[1] == :at
                camera_specs[4] = res[2]
                camera_specs[5] = res[3]
                camera_specs[6] = res[4]
            elseif res[1] == :up
                camera_specs[7] = res[2]
                camera_specs[8] = res[3]
                camera_specs[9] = res[4]
            elseif res[1] == :fov
                camera_specs[10] = res[2]
            elseif res[1] == :res
                camera_specs[11] = res[2]
                camera_specs[12] = res[3]
            end
        end
    end
    
    s = create_scene(trunc(Int, camera_specs[11]), trunc(Int, camera_specs[12]))
    specify_camera(s, camera_specs[1:10]...)
    set_recursion_depth(s, 8)
    
    open(file_path, "r") do io
        for line in eachline(io)
            parse_line(s, line)
        end
    end
    
    println("RayTracing")
    @time ray_trace(s)
    println("Reformatting")
    array_image = ray_trace(s)

    image = colorview(RGB, array_image)
    
    println("Saving " * file_name * ".png")
    # Save the resulting image to a PNG file
    save("../results/" * file_name * ".png", image)
end


all_files = ["basilica", "cornell-blocks", "cornell-spheres", 
"cornell-spheres-crazy", "cornell-spheres-mod", "cornell-spheres-raytrace", 
"cornell", "envmap", "floor_sph", "sphere", "test", "uffizi"]

raytrace_scene("cornell-spheres-crazy")

# for file in all_files
#     raytrace_scene(file)
# end
