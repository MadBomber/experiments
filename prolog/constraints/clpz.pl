% clpz.pl -- SEND+MORE for Scryer Prolog and Trealla, using library(clpz).

:- use_module(library(clpz)).

digits(Vars)   :- Vars ins 0..9.
distinct(Vars) :- all_different(Vars).
search(Vars)   :- label(Vars).
