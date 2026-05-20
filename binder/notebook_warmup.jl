using LATeachingSuite, LAlatex, LinearAlgebra, LaTeXStrings, Random

Random.seed!(42)

A_ge, X_ge, B_ge = gen_gj_pb(3, 4, 3; maxint=2, num_rhs=1)
display(l_show("A X = B : ", A_ge, X_ge, " = ", B_ge))

pb = ShowGE{Rational{Int}}(A_ge, B_ge)
ref!(pb; gj=true)
show_system(pb; b_col=1)
show_layout!(pb; fig_scale=1.05)
show_backsubstitution!(pb; b_col=1, fig_scale=1.05)

A_qr = gen_qr_problem(3; family=:pythagorean, maxint=2)
qr_svg(A_qr)

_svg_ge, ge_spec = ge_bundle(A_ge, B_ge[:, 1])
display(ge_spec)

U_svd, Sigma_svd, Vt_svd, A_svd = gen_svd_problem([2, 1], [2, 1], [3, 1, 0]; maxint=2)
svd_svg(A_svd)
