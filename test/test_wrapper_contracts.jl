using Test
using LATeachingSuite
using GenLAProblems

function _py_ns_lat()
    py = LATeachingSuite.ensure_pythoncall!()
    types = Base.invokelatest(py.pyimport, "types")
    simple_namespace = Base.invokelatest(py.pygetattr, types, "SimpleNamespace")
    return Base.invokelatest(py.pycall, simple_namespace)
end

function _py_setattr_lat(obj, name::AbstractString, value)
    py = LATeachingSuite.ensure_pythoncall!()
    Base.invokelatest(py.pycall, py.pybuiltins.setattr, obj, name, value)
end

@testset "Top-level wrapper contracts" begin
    la = _py_ns_lat()
    ml = _py_ns_lat()

    _py_setattr_lat(la, "__version__", "la-test-version")
    _py_setattr_lat(la, "__build__", "la-test-build")
    _py_setattr_lat(ml, "__version__", "ml-test-version")
    _py_setattr_lat(ml, "__build__", "ml-test-build")

    old_la = LATeachingSuite._LAFigureSpecs[]
    old_ml = LATeachingSuite._matrixlayout[]
    try
        LATeachingSuite._LAFigureSpecs[] = la
        LATeachingSuite._matrixlayout[] = ml

        @test LATeachingSuite.load_LAFigureSpecs() === la
        @test LATeachingSuite.load_matrixlayout() === ml
        @test LATeachingSuite.la_version() == "la-test-version"
        @test LATeachingSuite.la_build() == "la-test-build"
        @test LATeachingSuite.ml_version() == "ml-test-version"
        @test LATeachingSuite.ml_build() == "ml-test-build"
    finally
        LATeachingSuite._LAFigureSpecs[] = old_la
        LATeachingSuite._matrixlayout[] = old_ml
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

    normal_eq_callouts = LATeachingSuite._normal_eq_callouts(3, ["b"])
    @test length(normal_eq_callouts) == 5
    @test normal_eq_callouts[1]["grid"] == (0, 1)
    @test normal_eq_callouts[1]["side"] == "right"
    @test normal_eq_callouts[2]["grid"] == (1, 0)
    @test normal_eq_callouts[2]["side"] == "left"
    @test all(haskey(c, "label") for c in normal_eq_callouts)
    @test all(!haskey(c, "name_specs") for c in normal_eq_callouts)

    la_ge = _py_ns_lat()
    _py_setattr_lat(la_ge, "ge_svg", (args...; kwargs...) -> "<svg>ge</svg>")
    old_ge_la = LATeachingSuite._LAFigureSpecs[]
    try
        LATeachingSuite._LAFigureSpecs[] = la_ge
        @test LATeachingSuite.ge_svg([[nothing, [1 0; 0 1]]]) isa LATeachingSuite.SVGOut
        @test !isdefined(LATeachingSuite, :matrixlayout_ge)
        @test isdefined(LATeachingSuite, :_matrixlayout_ge)
    finally
        LATeachingSuite._LAFigureSpecs[] = old_ge_la
    end

    ge_seen = Dict{Symbol,Any}()
    decoration_specs = [Dict("grid" => (0, 1), "rows" => (0, 1), "cols" => (0, 0), "background" => "yellow!40", "padding_pt" => 1)]
    la_ge_bg = _py_ns_lat()
    _py_setattr_lat(la_ge_bg, "ge_svg", (args...; kwargs...) -> begin
        empty!(ge_seen)
        merge!(ge_seen, Dict(kwargs))
        "<svg>ge-bg</svg>"
    end)
    try
        LATeachingSuite._LAFigureSpecs[] = la_ge_bg
        svg = LATeachingSuite.ge_svg([[nothing, [1 0; 0 1]]]; decorations=decoration_specs)
        @test svg isa LATeachingSuite.SVGOut
        @test ge_seen[:decorations] == decoration_specs
        @test get(ge_seen, :decorators, nothing) === nothing
        @test !haskey(ge_seen, :bg_for_entries)

        callouts = [Dict("grid" => (0, 1), "label" => "A", "side" => "right")]
        decorations = [Dict("grid" => (0, 1), "rows" => (0, 0), "cols" => (0, 1), "background" => "yellow!35")]
        text_annotations = [Dict("grid_row" => 0, "text" => "\\qquad note")]
        pivot_locs = [Dict("grid" => (0, 1), "entries" => [(0, 0)])]
        rowechelon_paths = [Dict("grid" => (0, 1), "pivots" => [(0, 0)], "case" => "vv")]
        svg = LATeachingSuite.ge_svg(
            [[nothing, [1 0; 0 1]]];
            callouts=callouts,
            decorations=decorations,
            text_annotations=text_annotations,
            pivot_locs=pivot_locs,
            rowechelon_paths=rowechelon_paths,
        )
        @test svg isa LATeachingSuite.SVGOut
        @test ge_seen[:callouts] == callouts
        @test ge_seen[:decorations] == decorations
        @test ge_seen[:text_annotations] == text_annotations
        @test ge_seen[:pivot_locs] == pivot_locs
        @test ge_seen[:rowechelon_paths] == rowechelon_paths
        @test !haskey(ge_seen, :specs)
    finally
        LATeachingSuite._LAFigureSpecs[] = old_ge_la
    end

    la_show_layout = _py_ns_lat()
    _py_setattr_lat(la_show_layout, "ge_svg", (args...; kwargs...) -> begin
        empty!(ge_seen)
        merge!(ge_seen, Dict(kwargs))
        "<svg>show-layout</svg>"
    end)
    try
        LATeachingSuite._LAFigureSpecs[] = la_show_layout
        pb = ShowGE{Rational{Int}}([1 2; 3 4], [5, 6]; output_dir="/tmp/la", output_stem="layout_example")
        @test pb.output_stem == "layout_example"
        ref!(pb)
        svg = show_layout!(pb; fig_scale=1.1)
        @test svg isa LATeachingSuite.SVGOut
        @test ge_seen[:output_dir] == "/tmp/la"
        @test ge_seen[:output_stem] == "layout_example"
        @test !hasfield(typeof(pb), :pivot_list)
        @test !hasfield(typeof(pb), :bg_for_entries)
        @test !hasfield(typeof(pb), :ref_path_list)
        @test hasfield(typeof(pb), :pivot_locs)
        @test hasfield(typeof(pb), :decorations)
        @test hasfield(typeof(pb), :rowechelon_paths)
        @test ge_seen[:pivot_locs] !== nothing
        @test ge_seen[:decorations] !== nothing
        @test ge_seen[:rowechelon_paths] !== nothing
        @test ge_seen[:variable_summary] !== nothing
        @test ge_seen[:fig_scale] == 1.1
    finally
        LATeachingSuite._LAFigureSpecs[] = old_ge_la
    end

    la = _py_ns_lat()
    ml = _py_ns_lat()
    py = LATeachingSuite.ensure_pythoncall!()
    _py_setattr_lat(la, "qr_bundle", (args...; kwargs...) -> begin
        matrices = Any[
            Any[nothing, nothing, [1 0; 0 1], [1 0; 0 1]],
            Any[nothing, [1 0; 0 1], [1 0; 0 1], [1 0; 0 1]],
            Any[[1 0; 0 1], [1 0; 0 1], [1 0; 0 1], nothing],
        ]
        spec = Base.invokelatest(py.pydict, Dict("kind" => "qr", "matrices" => matrices))
        Base.invokelatest(py.pydict, Dict("spec" => spec, "svg" => "<svg>qr-bundle</svg>"))
    end)
    captured_qr_arg = Ref{Any}(nothing)
    _py_setattr_lat(la, "gram_schmidt_qr_matrices", (args...; kwargs...) -> begin
        captured_qr_arg[] = first(args)
        Any[
            Any[nothing, nothing, [1 0; 0 1], [1 0; 0 1]],
            Any[nothing, [1 0; 0 1], [1 0; 0 1], [1 0; 0 1]],
            Any[[1 0; 0 1], [1 0; 0 1], [1 0; 0 1], nothing],
        ]
    end)
    _py_setattr_lat(la, "qr_spec_from_matrices", (mats; kwargs...) ->
        Base.invokelatest(py.pydict, Dict("kind" => "qr", "matrices" => mats))
    )
    _py_setattr_lat(ml, "render_qr_svg", (; spec, kwargs...) -> "<svg>qr-figure</svg>")
    _py_setattr_lat(la, "qr_matrices_from_grid", args ->
        Dict(
            "A" => [1 0; 0 1],
            "W" => [1 0; 0 1],
            "WtA" => [1 0; 0 1],
            "WtW" => [1 0; 0 1],
            "S" => [1 0; 0 1],
            "Qt" => [1 0; 0 1],
            "Q" => [1 0; 0 1],
            "R" => [1 0; 0 1],
        )
    )
    old_la = LATeachingSuite._LAFigureSpecs[]
    old_ml = LATeachingSuite._matrixlayout[]
    try
        LATeachingSuite._LAFigureSpecs[] = la
        LATeachingSuite._matrixlayout[] = ml
        svg_only = LATeachingSuite.qr_svg([1 0; 0 1])
        svg_bundle, spec = LATeachingSuite.qr_bundle([1 0; 0 1])
        svg_figure, mats = LATeachingSuite.qr_figure([1 0; 0 1])
        qr = LATeachingSuite.qr_matrices_from_spec(spec)
        qr_grid = LATeachingSuite.qr_matrices_from_grid(:fake_grid)
        Q = LATeachingSuite.q_factor_from_spec(spec)
        R = LATeachingSuite.r_factor_from_spec(spec)
        @test svg_only isa LATeachingSuite.SVGOut
        @test svg_only.svg == svg_bundle.svg
        @test svg_figure isa LATeachingSuite.SVGOut
        @test svg_figure.svg == "<svg>qr-figure</svg>"
        @test mats[1][3] == [1 0; 0 1]
        @test captured_qr_arg[] == [[1, 0], [0, 1]]
        @test captured_qr_arg[] isa Vector{<:Vector}
        @test qr.Q == [1 0; 0 1]
        @test qr.R == [1 0; 0 1]
        @test qr_grid.Q == [1 0; 0 1]
        @test qr_grid.R == [1 0; 0 1]
        @test Q == [1 0; 0 1]
        @test R == [1 0; 0 1]
    finally
        LATeachingSuite._LAFigureSpecs[] = old_la
        LATeachingSuite._matrixlayout[] = old_ml
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

@testset "Exact rational Python literal bridge" begin
    A = Rational{Int}[1//2 -3//4; 0//1 5//6]
    b = Rational{Int}[7//8, -9//10]
    C = Complex{Rational{Int}}[complex(1//2, 3//4) 0//1; complex(-2//3, 1//5) 4//1]
    encoded = [((1, 2), (3, 4)) (0, 1); (-2, 3) ((4, 1), (0, 1))]

    A2 = LATeachingSuite._python_exact_literal(A)
    b2 = LATeachingSuite._python_exact_literal(b)
    C2 = LATeachingSuite._python_exact_literal(C)
    encoded2 = LATeachingSuite._python_exact_literal_if_needed(encoded)

    @test A2 == [[(1, 2), (-3, 4)], [(0, 1), (5, 6)]]
    @test b2 == [(7, 8), (-9, 10)]
    @test C2 == [[((1, 2), (3, 4)), ((0, 1), (0, 1))], [((-2, 3), (1, 5)), ((4, 1), (0, 1))]]
    @test encoded2 == [[((1, 2), (3, 4)), (0, 1)], [(-2, 3), ((4, 1), (0, 1))]]
    @test A2 isa Vector{<:Vector}
    @test b2 isa Vector
end

@testset "ShowGE system display exact RHS bridge" begin
    A, _, B = gen_gj_pb(3, 5, 3; maxint=2, pivot_in_first_col=true, num_rhs=1, has_zeros=true)
    pb = ShowGE{Rational{Int}}(A, B)
    A2, b2 = LATeachingSuite._system_matrix_rhs(pb; b_mat=1, b_col=1)

    @test A2 == LATeachingSuite._python_exact_literal(pb.A)
    @test b2 == LATeachingSuite._python_exact_literal(vec(pb.B[1]))

    la = _py_ns_lat()
    ml = _py_ns_lat()
    seen = Dict{Symbol,Any}()
    _py_setattr_lat(la, "linear_system_tex", (args...; kwargs...) -> begin
        seen[:A] = args[1]
        seen[:b] = args[2]
        seen[:kwargs] = Dict(kwargs)
        raw"\systeme{x_1=1}"
    end)
    _py_setattr_lat(ml, "backsubst_svg", (args...; kwargs...) -> begin
        merge!(seen, Dict(kwargs))
        "<svg>system</svg>"
    end)

    old_la = LATeachingSuite._LAFigureSpecs[]
    old_ml = LATeachingSuite._matrixlayout[]
    try
        LATeachingSuite._LAFigureSpecs[] = la
        LATeachingSuite._matrixlayout[] = ml
        svg = show_system(pb; b_mat=1, b_col=1, fig_scale=1.2, output_stem="system_demo")
        @test svg isa LATeachingSuite.SVGOut
        @test seen[:A] == A2
        @test seen[:b] == b2
        @test seen[:show_system] === true
        @test seen[:show_cascade] === false
        @test seen[:show_solution] === false
        @test seen[:fig_scale] == 1.2
        @test seen[:output_stem] == "system_demo"
    finally
        LATeachingSuite._LAFigureSpecs[] = old_la
        LATeachingSuite._matrixlayout[] = old_ml
    end
end

@testset "ShowGE backsubstitution before ref" begin
    A, _, B = gen_gj_pb(3, 5, 3; maxint=2, pivot_in_first_col=true, num_rhs=1, has_zeros=true)
    pb = ShowGE{Rational{Int}}(A, B)
    A2, b2 = LATeachingSuite._backsub_ref(pb; b_mat=1, b_col=1)
    @test A2 isa Vector{<:Vector}
    @test b2 isa Vector

    la = _py_ns_lat()
    ml = _py_ns_lat()
    seen = Dict{Symbol,Any}()
    _py_setattr_lat(la, "backsubstitution_tex", (args...; kwargs...) -> begin
        seen[:A] = args[1]
        seen[:b] = args[2]
        seen[:kwargs] = Dict(kwargs)
        ["x_1 = 1"]
    end)
    _py_setattr_lat(ml, "backsubst_svg", (args...; kwargs...) -> begin
        merge!(seen, Dict(kwargs))
        "<svg>backsub</svg>"
    end)

    old_la = LATeachingSuite._LAFigureSpecs[]
    old_ml = LATeachingSuite._matrixlayout[]
    try
        LATeachingSuite._LAFigureSpecs[] = la
        LATeachingSuite._matrixlayout[] = ml
        svg = show_backsubstitution!(pb; b_mat=1, b_col=1, param_name="\\beta", fig_scale=1.3, output_stem="backsub_demo",
            render_opts=Dict("padding" => (LATeachingSuite.mm_to_px(10), LATeachingSuite.mm_to_px(10), 4, 4), "frame" => true))
        @test svg isa LATeachingSuite.SVGOut
        @test seen[:A] == A2
        @test seen[:b] == b2
        @test seen[:show_system] === false
        @test seen[:show_cascade] === true
        @test seen[:show_solution] === false
        @test seen[:fig_scale] == 1.3
        @test seen[:output_stem] == "backsub_demo"
        @test seen[:kwargs][:param_name] == "\\beta"
        @test seen[:render_opts]["padding"] == (LATeachingSuite.mm_to_px(10), LATeachingSuite.mm_to_px(10), 4, 4)
        @test seen[:render_opts]["frame"] === true
    finally
        LATeachingSuite._LAFigureSpecs[] = old_la
        LATeachingSuite._matrixlayout[] = old_ml
    end
end

@testset "Bundle wrapper forwarding contracts" begin
    la = _py_ns_lat()
    seen = Dict{Symbol,Dict{Symbol,Any}}()

    function fake_bundle(kind::Symbol)
        return function(args...; kwargs...)
            seen[kind] = Dict(kwargs)
            py = LATeachingSuite.ensure_pythoncall!()
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

    old_la = LATeachingSuite._LAFigureSpecs[]
    try
        LATeachingSuite._LAFigureSpecs[] = la

        for (kind, fn) in [
            (:ge, LATeachingSuite.ge_bundle),
            (:qr, LATeachingSuite.qr_bundle),
            (:eig, LATeachingSuite.eig_bundle),
            (:svd, LATeachingSuite.svd_bundle),
        ]
            svg, spec = fn([1 0; 0 1]; output_dir="/tmp/lat", output_stem="bundle_demo", render_opts=Dict("crop" => "tight"))
            @test svg isa LATeachingSuite.SVGOut
            @test occursin(string(kind), svg.svg)
            @test seen[kind][:output_dir] == "/tmp/lat"
            @test seen[kind][:output_stem] == "bundle_demo"
            @test haskey(seen[kind], :render_opts)
            py = LATeachingSuite.ensure_pythoncall!()
            @test Base.invokelatest(py.pyconvert, String, spec["kind"]) == String(kind)
            @test Base.invokelatest(py.pyconvert, Int, spec["argc"]) == 1
        end
    finally
        LATeachingSuite._LAFigureSpecs[] = old_la
    end
end

@testset "Bundle wrapper render-error contract" begin
    la = _py_ns_lat()
    py = LATeachingSuite.ensure_pythoncall!()
    _py_setattr_lat(la, "ge_bundle", (args...; kwargs...) ->
        Base.invokelatest(py.pydict, Dict(
            "spec" => Base.invokelatest(py.pydict, Dict("kind" => "ge")),
            "svg" => py.pybuiltins.None,
            "render_error" => "latexmk failed",
        ))
    )

    old_la = LATeachingSuite._LAFigureSpecs[]
    try
        LATeachingSuite._LAFigureSpecs[] = la
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
        LATeachingSuite._LAFigureSpecs[] = old_la
    end
end

@testset "Direct SVG wrapper contracts" begin
    la = _py_ns_lat()
    _py_setattr_lat(la, "eig_svg", (args...; kwargs...) -> "<svg>eig</svg>")
    _py_setattr_lat(la, "svd_svg", (args...; kwargs...) -> "<svg>svd</svg>")

    old_la = LATeachingSuite._LAFigureSpecs[]
    try
        LATeachingSuite._LAFigureSpecs[] = la
        @test LATeachingSuite.eig_svg([1 0; 0 1]) isa LATeachingSuite.SVGOut
        @test LATeachingSuite.svd_svg([1 0; 0 1]) isa LATeachingSuite.SVGOut
    finally
        LATeachingSuite._LAFigureSpecs[] = old_la
    end
end
