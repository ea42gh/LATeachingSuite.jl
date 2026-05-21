using Test
using LATeachingSuite
using GenLAProblems

function _py_ns_lat()
    py = GenLAProblems._ensure_pythoncall()
    types = Base.invokelatest(py.pyimport, "types")
    simple_namespace = Base.invokelatest(py.pygetattr, types, "SimpleNamespace")
    return Base.invokelatest(py.pycall, simple_namespace)
end

function _py_setattr_lat(obj, name::AbstractString, value)
    py = GenLAProblems._ensure_pythoncall()
    Base.invokelatest(py.pycall, py.pybuiltins.setattr, obj, name, value)
end

@testset "Top-level wrapper contracts" begin
    la = _py_ns_lat()
    ml = _py_ns_lat()

    _py_setattr_lat(la, "__version__", "la-test-version")
    _py_setattr_lat(la, "__build__", "la-test-build")
    _py_setattr_lat(ml, "__version__", "ml-test-version")
    _py_setattr_lat(ml, "__build__", "ml-test-build")

    old_la = GenLAProblems._LAFigureSpecs[]
    old_ml = GenLAProblems._matrixlayout[]
    try
        GenLAProblems._LAFigureSpecs[] = la
        GenLAProblems._matrixlayout[] = ml

        @test LATeachingSuite.load_LAFigureSpecs() === la
        @test LATeachingSuite.load_matrixlayout() === ml
        @test LATeachingSuite.la_version() == "la-test-version"
        @test LATeachingSuite.la_build() == "la-test-build"
        @test LATeachingSuite.ml_version() == "ml-test-version"
        @test LATeachingSuite.ml_build() == "ml-test-build"
    finally
        GenLAProblems._LAFigureSpecs[] = old_la
        GenLAProblems._matrixlayout[] = old_ml
    end
end

@testset "Workflow wrapper delegation contracts" begin
    @test !isdefined(GenLAProblems, :ShowGE)

    @test any(m -> m.module === LATeachingSuite, methods(LATeachingSuite.ref!))
    @test any(m -> m.module === LATeachingSuite, methods(LATeachingSuite.show_layout!))
    @test any(m -> m.module === LATeachingSuite, methods(LATeachingSuite.show_system))
    @test any(m -> m.module === LATeachingSuite, methods(LATeachingSuite.create_cascade!))
    @test any(m -> m.module === LATeachingSuite, methods(LATeachingSuite.show_backsubstitution!))
    @test any(m -> m.module === LATeachingSuite, methods(LATeachingSuite.show_solution!))
    @test hasmethod(LATeachingSuite.show_backsubstitution, Tuple{Any,Any})
    @test hasmethod(LATeachingSuite.show_forwardsubstitution, Tuple{Any,Any})
    @test hasmethod(LATeachingSuite.show_solution, Tuple{Any})
    @test any(m -> m.module === LATeachingSuite, methods(LATeachingSuite.solutions))
    @test any(m -> m.module === LATeachingSuite, methods(LATeachingSuite.lhs_matrix))
    @test any(m -> m.module === LATeachingSuite, methods(LATeachingSuite.rhs_matrix))
    @test any(m -> m.module === LATeachingSuite, methods(LATeachingSuite.rhs_column))

    la_ge = _py_ns_lat()
    _py_setattr_lat(la_ge, "ge_svg", (args...; kwargs...) -> "<svg>ge</svg>")
    old_ge_la = GenLAProblems._LAFigureSpecs[]
    try
        GenLAProblems._LAFigureSpecs[] = la_ge
        @test LATeachingSuite.ge_svg([[nothing, [1 0; 0 1]]]) isa LATeachingSuite.SVGOut
    finally
        GenLAProblems._LAFigureSpecs[] = old_ge_la
    end

    ge_seen = Dict{Symbol,Any}()
    bg_specs = [[0, 1, [(0, 0), [(0, 0), (1, 0)]], "yellow!40", 1]]
    la_ge_bg = _py_ns_lat()
    _py_setattr_lat(la_ge_bg, "ge_svg", (args...; kwargs...) -> begin
        empty!(ge_seen)
        merge!(ge_seen, Dict(kwargs))
        "<svg>ge-bg</svg>"
    end)
    try
        GenLAProblems._LAFigureSpecs[] = la_ge_bg
        svg = LATeachingSuite.ge_svg([[nothing, [1 0; 0 1]]]; bg_for_entries=bg_specs)
        @test svg isa LATeachingSuite.SVGOut
        @test ge_seen[:bg_for_entries] == bg_specs
        @test get(ge_seen, :decorators, nothing) === nothing
    finally
        GenLAProblems._LAFigureSpecs[] = old_ge_la
    end

    la = _py_ns_lat()
    _py_setattr_lat(la, "qr_bundle", (args...; kwargs...) -> begin
        py = GenLAProblems._ensure_pythoncall()
        matrices = Any[
            Any[nothing, nothing, [1 0; 0 1], [1 0; 0 1]],
            Any[nothing, [1 0; 0 1], [1 0; 0 1], [1 0; 0 1]],
            Any[[1 0; 0 1], [1 0; 0 1], [1 0; 0 1], nothing],
        ]
        spec = Base.invokelatest(py.pydict, Dict("kind" => "qr", "matrices" => matrices))
        Base.invokelatest(py.pydict, Dict("spec" => spec, "svg" => "<svg>qr-bundle</svg>"))
    end)
    old_la = GenLAProblems._LAFigureSpecs[]
    try
        GenLAProblems._LAFigureSpecs[] = la
        svg_only = LATeachingSuite.qr_svg([1 0; 0 1])
        svg_bundle, spec = LATeachingSuite.qr_bundle([1 0; 0 1])
        qr = LATeachingSuite.qr_matrices_from_spec(spec)
        Q = LATeachingSuite.q_factor_from_spec(spec)
        R = LATeachingSuite.r_factor_from_spec(spec)
        @test svg_only isa LATeachingSuite.SVGOut
        @test svg_only.svg == svg_bundle.svg
        @test qr.Q == [1 0; 0 1]
        @test qr.R == [1 0; 0 1]
        @test Q == [1 0; 0 1]
        @test R == [1 0; 0 1]
    finally
        GenLAProblems._LAFigureSpecs[] = old_la
    end
end

@testset "Display helper wrapper contracts" begin
    @test_throws ErrorException LATeachingSuite.py_show_svg(123)
    @test_throws ErrorException LATeachingSuite.show_svg(123)
    I2 = [1.0 0.0; 0.0 1.0]
    @test LATeachingSuite.l_show_svd(I2, I2, I2, I2, 1) === nothing
end

@testset "Spec query helpers" begin
    eig_spec = Dict(
        "lambda" => Any[2, 1],
        "ma" => Any[1, 1],
        "evecs" => Any[Any[[1, 0]], Any[[0, 1]]],
        "qvecs" => Any[Any[[1, 0]], Any[[0, 1]]],
    )
    @test LATeachingSuite.eig_eigenvalues(eig_spec) == [(1, 2), (1, 1)]
    @test LATeachingSuite.eig_eigenvectors(eig_spec, 2) == Any[[1, 0]]
    @test LATeachingSuite.eig_eigenvectors(eig_spec, 3) === nothing

    svd_spec = Dict(
        "sigma" => Any[3, 1, 0],
        "ma" => Any[1, 1, 1],
        "evecs" => Any[Any[[1, 0, 0]], Any[[0, 1, 0]], Any[[0, 0, 1]]],
        "qvecs" => Any[Any[[1, 0, 0]], Any[[0, 1, 0]], Any[[0, 0, 1]]],
        "uvecs" => Any[Any[[1, 0]], Any[[0, 1]], Any[[1, 1]]],
    )
    @test LATeachingSuite.svd_singular_values(svd_spec) == [(1, 3), (1, 1), (1, 0)]
    @test LATeachingSuite.svd_rank(svd_spec) == 2
    @test LATeachingSuite.svd_left_vectors(svd_spec, 1) == Any[[0, 1]]
    @test LATeachingSuite.svd_right_vectors(svd_spec, 3) == Any[[1, 0, 0]]
    @test LATeachingSuite.svd_left_vectors(svd_spec, 2) === nothing
end

@testset "Bundle wrapper forwarding contracts" begin
    la = _py_ns_lat()
    seen = Dict{Symbol,Dict{Symbol,Any}}()

    function fake_bundle(kind::Symbol)
        return function(args...; kwargs...)
            seen[kind] = Dict(kwargs)
            py = GenLAProblems._ensure_pythoncall()
            return Base.invokelatest(py.pydict, Dict(
                "spec" => Base.invokelatest(py.pydict, Dict("kind" => String(kind), "argc" => length(args))),
                "svg" => "<svg>$(kind)</svg>",
            ))
        end
    end

    _py_setattr_lat(la, "ge_bundle", fake_bundle(:ge))
    _py_setattr_lat(la, "qr_bundle", fake_bundle(:qr))
    _py_setattr_lat(la, "eig_bundle", fake_bundle(:eig))
    _py_setattr_lat(la, "svd_bundle", fake_bundle(:svd))

    old_la = GenLAProblems._LAFigureSpecs[]
    try
        GenLAProblems._LAFigureSpecs[] = la

        for (kind, fn) in [
            (:ge, LATeachingSuite.ge_bundle),
            (:qr, LATeachingSuite.qr_bundle),
            (:eig, LATeachingSuite.eig_bundle),
            (:svd, LATeachingSuite.svd_bundle),
        ]
            svg, spec = fn([1 0; 0 1]; output_dir="/tmp/lat", render_opts=Dict("crop" => "tight"))
            @test svg isa LATeachingSuite.SVGOut
            @test occursin(string(kind), svg.svg)
            @test seen[kind][:output_dir] == "/tmp/lat"
            @test haskey(seen[kind], :render_opts)
            py = GenLAProblems._ensure_pythoncall()
            @test Base.invokelatest(py.pyconvert, String, spec["kind"]) == String(kind)
            @test Base.invokelatest(py.pyconvert, Int, spec["argc"]) == 1
        end
    finally
        GenLAProblems._LAFigureSpecs[] = old_la
    end
end

@testset "Bundle wrapper render-error contract" begin
    la = _py_ns_lat()
    py = GenLAProblems._ensure_pythoncall()
    _py_setattr_lat(la, "ge_bundle", (args...; kwargs...) ->
        Base.invokelatest(py.pydict, Dict(
            "spec" => Base.invokelatest(py.pydict, Dict("kind" => "ge")),
            "svg" => py.pybuiltins.None,
            "render_error" => "latexmk failed",
        ))
    )

    old_la = GenLAProblems._LAFigureSpecs[]
    try
        GenLAProblems._LAFigureSpecs[] = la
        err = try
            LATeachingSuite.ge_bundle([1 0; 0 1])
            nothing
        catch e
            e
        end
        @test err isa ErrorException
        @test occursin("render failed", sprint(showerror, err))
        @test occursin("latexmk failed", sprint(showerror, err))
    finally
        GenLAProblems._LAFigureSpecs[] = old_la
    end
end

@testset "Direct SVG wrapper contracts" begin
    la = _py_ns_lat()
    _py_setattr_lat(la, "eig_svg", (args...; kwargs...) -> "<svg>eig</svg>")
    _py_setattr_lat(la, "svd_svg", (args...; kwargs...) -> "<svg>svd</svg>")

    old_la = GenLAProblems._LAFigureSpecs[]
    try
        GenLAProblems._LAFigureSpecs[] = la
        @test LATeachingSuite.eig_svg([1 0; 0 1]) isa LATeachingSuite.SVGOut
        @test LATeachingSuite.svd_svg([1 0; 0 1]) isa LATeachingSuite.SVGOut
    finally
        GenLAProblems._LAFigureSpecs[] = old_la
    end
end
