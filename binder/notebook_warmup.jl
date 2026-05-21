using LATeachingSuite, LAlatex, LinearAlgebra, LaTeXStrings, Random

Random.seed!(42)

A_ge, X_ge, B_ge = gen_gj_pb(3, 4, 3; maxint=2, num_rhs=1)
display(l_show("A X = B : ", A_ge, X_ge, " = ", B_ge))

pb_ge = ShowGE{Rational{Int}}(A_ge, B_ge)
show_system(pb_ge; b_mat=1, b_col=1)
ref!(pb_ge; gj=true)
show_layout!(pb_ge; fig_scale=1.05)
show_backsubstitution!(pb_ge; b_mat=1, b_col=1, fig_scale=1.05)
show_solution!(pb_ge; b_mat=1, b_col=1, fig_scale=1.05)
Xp_ge, Xh_ge = solutions(pb_ge; b_mat=1)
display(l_show("x_p = ", Xp_ge, L"\qquad x_h = ", Xh_ge))

A_multi, X_multi, B_multi = gen_gj_pb(3, 4, 3; maxint=2, num_rhs=2)
B_split = (B_multi[:, 1:1], B_multi[:, 2:2])
pb_multi = ShowGE{Rational{Int}}(A_multi, B_split)
ref!(pb_multi; gj=true)
rhs_matrix(pb_multi, 1)
rhs_column(pb_multi, 2, 1)
solutions(pb_multi; b_mat=2, b_col=1)

A_bad, B_bad = gen_inconsistent_gj_pb(4, 6, 3; maxint=2, num_rhs=1)
display(l_show("Inconsistent A x = b : ", A_bad, " = ", B_bad))
pb_bad = ShowGE{Rational{Int}}(A_bad, B_bad)
ref!(pb_bad; gj=true)
show_layout!(pb_bad; fig_scale=1.05)

A_ls, X_ls, B_ls = gen_gj_pb(3, 4, 2; maxint=2, pivot_in_first_col=true, num_rhs=1, has_zeros=true)
pb_ls = ShowGE{Rational{Int}}(A_ls, B_ls)
show_system(pb_ls; b_mat=1, b_col=1)
ref!(pb_ls; normal_eq=true)
show_layout!(pb_ls; fig_scale=1.05)

A_qr = gen_qr_problem(3; family=:pythagorean, maxint=2)
qr_svg(A_qr)
svg_qr, qr_spec = qr_bundle(A_qr)
display(svg_qr)
display(qr_spec)

S_eig, Lambda_eig, S_inv_eig, A_eig = gen_eigenproblem([3, -1, 2]; maxint=2)
display(l_show("A = ", A_eig, L"\qquad \Lambda = ", Lambda_eig))
eig_svg(A_eig)
svg_eig, eig_spec = eig_bundle(A_eig)
display(svg_eig)
eig_matrices_from_spec(eig_spec)
eig_eigenvalues(eig_spec)
eig_eigenvectors(eig_spec, eig_spec["lambda"][1])

_svg_ge, ge_spec = ge_bundle(A_ge, B_ge[:, 1])
display(ge_spec)

U_svd, Sigma_svd, Vt_svd, A_svd = gen_svd_problem([2, 1], [2, 1], [3, 1, 0]; maxint=2)
display(l_show("A = ", A_svd, L"\qquad \Sigma = ", Sigma_svd))
svd_svg(A_svd)
svg_svd, svd_spec = svd_bundle(A_svd)
display(svg_svd)
svd_matrices_from_spec(svd_spec)
svd_singular_values(svd_spec)
σ1 = svd_spec["sigma"][1]
svd_rank(svd_spec)
svd_left_vectors(svd_spec, σ1)
svd_right_vectors(svd_spec, σ1)

la_version()
ml_version()
