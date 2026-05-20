using Test

let
    pycall_exe = get(ENV, "JULIA_PYTHONCALL_EXE", "")
    if isempty(pycall_exe) || !isfile(pycall_exe)
        py = get(ENV, "PYTHON", "")
        if isempty(py) || !isfile(py)
            py = something(Sys.which("python3"), "")
        end
        ENV["JULIA_PYTHONCALL_EXE"] = py
    end
    ENV["JULIA_CONDAPKG_BACKEND"] = get(ENV, "JULIA_CONDAPKG_BACKEND", "Null")
    ENV["CONDAPKG_BACKEND"] = get(ENV, "CONDAPKG_BACKEND", "Null")

    repo = normpath(joinpath(@__DIR__, "..", ".."))
    py_paths = [
        joinpath(repo, ".pydeps"),
        joinpath(repo, "LAFigureSpecs"),
        joinpath(repo, "matrixlayout"),
    ]
    existing = get(ENV, "PYTHONPATH", "")
    parts = isempty(existing) ? String[] : split(existing, ':')
    for p in reverse(py_paths)
        if !(p in parts)
            pushfirst!(parts, p)
        end
    end
    ENV["PYTHONPATH"] = join(parts, ':')
end

using LATeachingSuite
using GenLAProblems

@testset "LATeachingSuite" begin
    @test isdefined(LATeachingSuite, :ShowGE)
    @test isdefined(LATeachingSuite, :WorkflowDisplay)
    @test isdefined(LATeachingSuite, :PythonBridge)
    @test isdefined(LATeachingSuite, :load_LAFigureSpecs)
    @test isdefined(LATeachingSuite, :load_matrixlayout)
    @test isdefined(LATeachingSuite, :ref!)
    @test isdefined(LATeachingSuite, :show_layout!)
    @test isdefined(LATeachingSuite, :show_system)
    @test isdefined(LATeachingSuite, :create_cascade!)
    @test isdefined(LATeachingSuite, :show_backsubstitution!)
    @test isdefined(LATeachingSuite, :show_solution!)
    @test isdefined(LATeachingSuite, :show_backsubstitution)
    @test isdefined(LATeachingSuite, :show_forwardsubstitution)
    @test isdefined(LATeachingSuite, :show_solution)
    @test isdefined(LATeachingSuite, :solutions)
    @test isdefined(LATeachingSuite, :rhs_block)
    @test isdefined(LATeachingSuite, :ge_svg)
    @test isdefined(LATeachingSuite, :qr_svg)
    @test isdefined(LATeachingSuite, :eig_svg)
    @test isdefined(LATeachingSuite, :svd_svg)
    @test isdefined(LATeachingSuite, :qr_figure)
    @test isdefined(LATeachingSuite, :show_svg)
    @test isdefined(LATeachingSuite, :py_show_svg)
    @test isdefined(LATeachingSuite, :l_show_svd)
    @test isdefined(LATeachingSuite, :ge_bundle)
    @test isdefined(LATeachingSuite, :qr_bundle)
    @test isdefined(LATeachingSuite, :eig_bundle)
    @test isdefined(LATeachingSuite, :svd_bundle)
    @test isdefined(LATeachingSuite.WorkflowDisplay, :show_layout!)
    @test isdefined(LATeachingSuite.WorkflowDisplay, :ShowGE)
    @test isdefined(LATeachingSuite.PythonBridge, :ensure_pythoncall!)
    @test isdefined(LATeachingSuite.PythonBridge, :load_LAFigureSpecs)
    @test hasmethod(LATeachingSuite.load_LAFigureSpecs, Tuple{})
    @test hasmethod(LATeachingSuite.load_matrixlayout, Tuple{})
    @test hasmethod(LATeachingSuite.ref!, Tuple{Any})
    @test hasmethod(LATeachingSuite.show_backsubstitution, Tuple{Any,Any})
    @test hasmethod(LATeachingSuite.ge_svg, Tuple{Any})
    @test hasmethod(LATeachingSuite.eig_svg, Tuple{Any})
    @test hasmethod(LATeachingSuite.svd_svg, Tuple{Any})
    @test hasmethod(LATeachingSuite.qr_figure, Tuple{Any})
    @test hasmethod(LATeachingSuite.show_svg, Tuple{Any})
end

include("test_wrapper_contracts.jl")
include("test_bundle_parity.jl")
