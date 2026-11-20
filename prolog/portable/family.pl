% family.pl -- relations, not functions.
%
% A Prolog predicate has no fixed "input" and "output".  The same
% parent/2 facts answer "who are X's children?", "who are X's parents?"
% and "list every pair" depending on which arguments are left unbound.

:- initialization(main).

parent(alice, bob).
parent(alice, carol).
parent(bob,   dave).
parent(bob,   erin).
parent(carol, frank).
parent(dave,  grace).

grandparent(X, Z) :- parent(X, Y), parent(Y, Z).

sibling(X, Y) :- parent(P, X), parent(P, Y), X \== Y.

cousin(X, Y) :- parent(PX, X), parent(PY, Y), sibling(PX, PY).

% Recursion: an ancestor is a parent, or a parent of an ancestor.
ancestor(X, Y) :- parent(X, Y).
ancestor(X, Y) :- parent(X, Z), ancestor(Z, Y).

% show(+Label, ?Template, :Goal) -- print every solution of Goal.
show(Label, Template, Goal) :-
    findall(Template, Goal, Solutions),
    write(Label), write(': '), write(Solutions), nl.

main :-
    show('children of alice     ', C,   parent(alice, C)),
    show('parents of dave       ', P,   parent(P, dave)),
    show('grandchildren of alice', G,   grandparent(alice, G)),
    show('siblings of dave      ', S,   sibling(dave, S)),
    show('cousin pairs          ', A-B, cousin(A, B)),
    show('ancestors of grace    ', An,  ancestor(An, grace)),
    show('descendants of bob    ', D,   ancestor(bob, D)),
    halt.
