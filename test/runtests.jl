using Test
using LATeachingSuite

@testset "LATeachingSuite" begin
    @test isdefined(LATeachingSuite, :ShowGE)
    @test isdefined(LATeachingSuite, :WorkflowDisplay)
    @test isdefined(LATeachingSuite, :PythonBridge)
    @test isdefined(LATeachingSuite, :load_LAFigureSpecs)
    @test isdefined(LATeachingSuite, :load_matrixlayout)
    @test isdefined(LATeachingSuite, :show_svg)
    @test isdefined(LATeachingSuite, :py_show_svg)
    @test isdefined(LATeachingSuite, :l_show_svd)
    @test isdefined(LATeachingSuite.WorkflowDisplay, :show_layout!)
    @test isdefined(LATeachingSuite.WorkflowDisplay, :ShowGE)
    @test isdefined(LATeachingSuite.PythonBridge, :ensure_pythoncall!)
    @test isdefined(LATeachingSuite.PythonBridge, :load_LAFigureSpecs)
    @test hasmethod(LATeachingSuite.load_LAFigureSpecs, Tuple{})
    @test hasmethod(LATeachingSuite.load_matrixlayout, Tuple{})
    @test hasmethod(LATeachingSuite.show_svg, Tuple{Any})
end
