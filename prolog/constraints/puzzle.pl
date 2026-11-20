% puzzle.pl -- SEND + MORE = MONEY, shared by every dialect file.
%
% Load a dialect file first, then this one, e.g.
%
%   swipl -q swi.pl puzzle.pl
%   scryer-prolog clpz.pl puzzle.pl
%   tpl clpz.pl puzzle.pl
%   gprolog --consult-file gnu.pl --consult-file puzzle.pl
%
% The dialect file supplies digits/1, distinct/1 and search/1, because
% each system names its finite-domain primitives differently.  The
% constraint operators (#=, #\=) are the same everywhere.  (include/1
% would be the ISO way to share this file, but Scryer does not have it.)
%
% Unlike the generate-and-test in portable/queens.pl, constraints prune
% the domains *before* any value is guessed: this puzzle is solved with
% almost no search.

puzzle([S,E,N,D,M,O,R,Y]) :-
    Vars = [S,E,N,D,M,O,R,Y],
    digits(Vars),
    distinct(Vars),
    S #\= 0,
    M #\= 0,
                 1000*S + 100*E + 10*N + D
               + 1000*M + 100*O + 10*R + E
    #= 10000*M + 1000*O + 100*N + 10*E + Y,
    search(Vars).

main :-
    puzzle([S,E,N,D,M,O,R,Y]),
    write('   '), write(S), write(E), write(N), write(D), nl,
    write(' + '), write(M), write(O), write(R), write(E), nl,
    write(' = '), write(M), write(O), write(N), write(E), write(Y), nl,
    halt.

:- initialization(main).
