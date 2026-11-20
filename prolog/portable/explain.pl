% explain.pl -- a meta-interpreter that explains its answers.
%
% Prolog programs are Prolog terms, so an interpreter for Prolog is three
% clauses.  This one also builds a proof tree, turning a yes/no access
% decision into "yes, and here is exactly why".

:- initialization(main).

:- dynamic(role/2).
:- dynamic(owns/2).
:- dynamic(classified/2).
:- dynamic(clearance/2).
:- dynamic(covers/2).
:- dynamic(may_read/2).

% ------------------------------------------------------------ the policy

role(ann, engineer).
role(bob, intern).
role(cy,  manager).

owns(bob, report7).

classified(wiki,    public).
classified(report7, internal).
classified(payroll, secret).

clearance(engineer, internal).
clearance(manager,  secret).

covers(Level, Level).
covers(secret, internal).

may_read(_User, Doc) :- classified(Doc, public).
may_read(User, Doc)  :- owns(User, Doc).
may_read(User, Doc)  :-
    role(User, Role),
    classified(Doc, Level),
    clearance(Role, Cleared),
    covers(Cleared, Level).

% ------------------------------------------------------ meta-interpreter
% prove(+Goal, -Proofs): Proofs is a list of Goal-SubProofs trees.

prove(true, []) :- !.
prove((A, B), Proofs) :- !,
    prove(A, PA),
    prove(B, PB),
    join(PA, PB, Proofs).
prove(Goal, [Goal-SubProofs]) :-
    clause(Goal, Body),
    prove(Body, SubProofs).

join([], L, L).
join([H|T], L, [H|R]) :- join(T, L, R).

% ---------------------------------------------------------------- output

print_proofs([], _).
print_proofs([Goal-Subs|Rest], Indent) :-
    indent(Indent), write(Goal),
    ( Subs == [] -> write('   (fact)') ; write('   because') ),
    nl,
    Deeper is Indent + 4,
    print_proofs(Subs, Deeper),
    print_proofs(Rest, Indent).

% indent(+N) -- write N spaces.  (tab/1 is not available in Scryer.)
indent(0) :- !.
indent(N) :- write(' '), N1 is N - 1, indent(N1).

% explain(+Goal) -- print every distinct proof of Goal, or say there is none.
explain(Goal) :-
    write('?- '), write(Goal), nl,
    findall(Proof, prove(Goal, Proof), Proofs),
    ( Proofs == []
    -> write('    no: nothing in the policy allows it'), nl
    ;  print_each(Proofs, 1)
    ),
    nl.

print_each([], _).
print_each([P|Ps], N) :-
    write('  proof '), write(N), write(':'), nl,
    print_proofs(P, 4),
    N1 is N + 1,
    print_each(Ps, N1).

main :-
    explain(may_read(ann, report7)),
    explain(may_read(bob, report7)),
    explain(may_read(cy,  report7)),
    explain(may_read(bob, payroll)),
    explain(may_read(bob, wiki)),
    write('Who may read payroll? '),
    findall(U, prove(may_read(U, payroll), _), Users),
    write(Users), nl,
    halt.
