using Test

let
    if !haskey(ENV, "JULIA_PYTHONCALL_EXE")
        py = get(ENV, "PYTHON", Sys.which("python3"))
        if py !== nothing
            ENV["JULIA_PYTHONCALL_EXE"] = py
        end
    end
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
    @test isdefined(LATeachingSuite, :show_ge_final)
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
