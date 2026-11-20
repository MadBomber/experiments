% queens.pl -- N-queens by generate-and-test with early pruning.
%
% Qs is a list where the Nth element is the row of the queen in column N.
% Each queen is checked against the ones already placed, so a bad partial
% board is abandoned immediately and backtracking tries the next row.

:- initialization(main).

queens(N, Qs) :-
    range(1, N, Rows),
    place(Rows, [], Qs).

place([], Qs, Qs).
place(Unplaced, Placed, Qs) :-
    pick(Q, Unplaced, Rest),
    safe(Q, 1, Placed),
    place(Rest, [Q|Placed], Qs).

% safe(+Row, +Distance, +PlacedRows) -- no placed queen shares a diagonal.
safe(_, _, []).
safe(Q, D, [P|Ps]) :-
    Q =\= P + D,
    Q =\= P - D,
    D1 is D + 1,
    safe(Q, D1, Ps).

% pick(?X, +List, -Rest) -- X is some element of List, Rest is the others.
pick(X, [X|T], T).
pick(X, [H|T], [H|R]) :- pick(X, T, R).

range(Lo, Hi, [])     :- Lo > Hi.
range(Lo, Hi, [Lo|T]) :- Lo =< Hi, Lo1 is Lo + 1, range(Lo1, Hi, T).

count([], 0).
count([_|T], N) :- count(T, N0), N is N0 + 1.

% ---------------------------------------------------------------- output

print_board(Qs, N) :-
    range(1, N, Cols),
    print_rows(Qs, Cols).

print_rows([], _).
print_rows([Q|Qs], Cols) :-
    print_row(Cols, Q),
    nl,
    print_rows(Qs, Cols).

print_row([], _).
print_row([C|Cs], Q) :-
    ( C =:= Q -> write(' Q') ; write(' .') ),
    print_row(Cs, Q).

report(N) :-
    findall(Qs, queens(N, Qs), All),
    count(All, Count),
    write(N), write(' queens: '), write(Count), write(' solutions'), nl.

main :-
    queens(8, First),
    write('first 8-queens solution: '), write(First), nl,
    print_board(First, 8),
    nl,
    report(4), report(5), report(6), report(7), report(8), report(9), report(10),
    halt.
