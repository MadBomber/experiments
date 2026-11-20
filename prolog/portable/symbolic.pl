% symbolic.pl -- parse, differentiate, simplify, evaluate.
%
% Three things Prolog is unusually good at, in about 80 lines:
%   1. DCGs: a grammar is directly executable as a parser.
%   2. Pattern matching on terms: the calculus rules read like a textbook.
%   3. Code is data: the parsed expression is an ordinary Prolog term
%      that `is` can evaluate once x has been substituted.

:- initialization(main).

% ---------------------------------------------------------------- parser
% Left-associative operators are handled with an accumulator argument.

expr(E) --> prod(T), expr_rest(T, E).

expr_rest(Acc, E) --> ['+'], prod(T), expr_rest(Acc+T, E).
expr_rest(Acc, E) --> ['-'], prod(T), expr_rest(Acc-T, E).
expr_rest(E, E)   --> [].

prod(T) --> power(F), prod_rest(F, T).

prod_rest(Acc, T) --> ['*'], power(F), prod_rest(Acc*F, T).
prod_rest(Acc, T) --> ['/'], power(F), prod_rest(Acc/F, T).
prod_rest(T, T)   --> [].

power(B^N) --> factor(B), ['^'], num(N).
power(F)   --> factor(F).

factor(N)      --> num(N).
factor(sin(E)) --> [s,i,n,'('], expr(E), [')'].
factor(cos(E)) --> [c,o,s,'('], expr(E), [')'].
factor(exp(E)) --> [e,x,p,'('], expr(E), [')'].
factor(ln(E))  --> [l,n,'('],   expr(E), [')'].
factor(x)      --> [x].
factor(E)      --> ['('], expr(E), [')'].

num(N) --> digit(D), digits(Ds), { number_chars(N, [D|Ds]) }.

digits([D|Ds]) --> digit(D), digits(Ds).
digits([])     --> [].

digit(D) --> [D], { D @>= '0', D @=< '9' }.

% parse(+Atom, -Expr)
parse(Atom, Expr) :-
    atom_chars(Atom, Chars),
    strip_spaces(Chars, Tokens),
    phrase(expr(Expr), Tokens),
    !.

strip_spaces([], []).
strip_spaces([' '|Cs], Ts) :- !, strip_spaces(Cs, Ts).
strip_spaces([C|Cs], [C|Ts]) :- strip_spaces(Cs, Ts).

% ------------------------------------------------------- differentiation
% d(+Expr, -Derivative) with respect to x.

d(x, 1).
d(N, 0)                        :- number(N).
d(U+V, DU+DV)                  :- d(U, DU), d(V, DV).
d(U-V, DU-DV)                  :- d(U, DU), d(V, DV).
d(U*V, DU*V+U*DV)              :- d(U, DU), d(V, DV).
d(U/V, (DU*V-U*DV)/V^2)        :- d(U, DU), d(V, DV).
d(U^N, N*U^N1*DU)              :- N1 is N-1, d(U, DU).
d(sin(U), cos(U)*DU)           :- d(U, DU).
d(cos(U), -(sin(U)*DU))        :- d(U, DU).
d(exp(U), exp(U)*DU)           :- d(U, DU).
d(ln(U),  DU/U)                :- d(U, DU).

% -------------------------------------------------------- simplification
% Simplify the sub-terms first, then apply one algebraic rule at the top.

simp(E, E) :- atomic(E), !.
simp(E, S) :- E =.. [Op, A, B], !, simp(A, SA), simp(B, SB), rule(Op, SA, SB, S).
simp(E, S) :- E =.. [F, A], simp(A, SA), S =.. [F, SA].

rule(Op, A, B, C)     :- number(A), number(B), Op \== (/), !, T =.. [Op, A, B], C is T.
rule(+, 0, X, X)      :- !.
rule(+, X, 0, X)      :- !.
rule(+, X, Y, 2*X)    :- X == Y, !.
rule(-, X, 0, X)      :- !.
rule(-, X, Y, 0)      :- X == Y, !.
rule(*, 0, _, 0)      :- !.
rule(*, _, 0, 0)      :- !.
rule(*, 1, X, X)      :- !.
rule(*, X, 1, X)      :- !.
rule(*, A, B*X, C*X)  :- number(A), number(B), !, C is A*B.
rule(/, 0, _, 0)      :- !.
rule(/, X, 1, X)      :- !.
rule(^, X, 1, X)      :- !.
rule(^, _, 0, 1)      :- !.
rule(Op, A, B, E)     :- E =.. [Op, A, B].

% ------------------------------------------------------------ evaluation
% eval(+Expr, +X, -Value) for polynomial expressions.

eval(x, X, X).
eval(N, _, N) :- number(N).
eval(E, X, V) :-
    E =.. [Op, A, B],
    eval(A, X, VA),
    eval(B, X, VB),
    T =.. [Op, VA, VB],
    V is T.

% ------------------------------------------------------------------ demo

demo(Source) :-
    parse(Source, Expr),
    d(Expr, Raw),
    simp(Raw, Derivative),
    write('f(x)  = '), write(Expr), nl,
    write('f''(x) = '), write(Derivative), nl, nl.

main :-
    demo('x^3 + 2*x^2 - 5*x + 7'),
    demo('sin(x) * x^2'),
    demo('exp(x*x)'),
    demo('ln(3*x + 1)'),
    demo('(x + 1) / (x - 1)'),
    parse('x^3 + 2*x^2 - 5*x + 7', F),
    d(F, DF0), simp(DF0, DF),
    eval(F, 2, V), eval(DF, 2, Slope),
    write('at x = 2: f = '), write(V),
    write(', slope = '), write(Slope), nl,
    halt.
