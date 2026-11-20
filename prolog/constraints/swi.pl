% swi.pl -- SEND+MORE for SWI-Prolog, using library(clpfd).

:- use_module(library(clpfd)).

digits(Vars)   :- Vars ins 0..9.
distinct(Vars) :- all_different(Vars).
search(Vars)   :- label(Vars).
