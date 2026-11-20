% zebra.pl -- the classic five-houses logic puzzle.
%
% There is no search algorithm here.  The program states the clues;
% unification and backtracking find the one street that satisfies them.

:- initialization(main).

% h(Colour, Nationality, Pet, Drink, Cigarette), listed left to right.

street(Hs) :-
    Hs = [h(_, norwegian, _, _, _), _, h(_, _, _, milk, _), _, _],
    elem(h(red, english, _, _, _), Hs),
    elem(h(_, spaniard, dog, _, _), Hs),
    elem(h(green, _, _, coffee, _), Hs),
    elem(h(_, ukrainian, _, tea, _), Hs),
    left_of(h(ivory, _, _, _, _), h(green, _, _, _, _), Hs),
    elem(h(_, _, snails, _, old_gold), Hs),
    elem(h(yellow, _, _, _, kools), Hs),
    next_to(h(_, _, _, _, chesterfield), h(_, _, fox, _, _), Hs),
    next_to(h(_, _, _, _, kools), h(_, _, horse, _, _), Hs),
    elem(h(_, _, _, orange_juice, lucky_strike), Hs),
    elem(h(_, japanese, _, _, parliament), Hs),
    next_to(h(_, norwegian, _, _, _), h(blue, _, _, _, _), Hs),
    elem(h(_, _, zebra, _, _), Hs),
    elem(h(_, _, _, water, _), Hs).

elem(X, [X|_]).
elem(X, [_|T]) :- elem(X, T).

left_of(A, B, [A,B|_]).
left_of(A, B, [_|T]) :- left_of(A, B, T).

next_to(A, B, Hs) :- left_of(A, B, Hs).
next_to(A, B, Hs) :- left_of(B, A, Hs).

print_houses([], _).
print_houses([H|Hs], N) :-
    write(N), write('  '), write(H), nl,
    N1 is N + 1,
    print_houses(Hs, N1).

main :-
    street(Hs),
    print_houses(Hs, 1),
    elem(h(_, ZebraOwner, zebra, _, _), Hs),
    elem(h(_, WaterDrinker, _, water, _), Hs),
    nl,
    write('The '), write(ZebraOwner), write(' owns the zebra.'), nl,
    write('The '), write(WaterDrinker), write(' drinks water.'), nl,
    halt.
