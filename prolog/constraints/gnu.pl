% gnu.pl -- SEND+MORE for GNU Prolog, using its built-in FD solver.

digits(Vars)   :- fd_domain(Vars, 0, 9).
distinct(Vars) :- fd_all_different(Vars).
search(Vars)   :- fd_labeling(Vars).
