%  demo.lgt -- sends a few messages to the policy objects and prints the answers.

:- object(demo).

	:- public(run/0).
	run :-
		show('office: who may read payroll  ', policy(office)::readers(payroll, A), A),
		show('office: what may ann read     ', policy(office)::readable(ann, B), B),
		show('office: what may bob read     ', policy(office)::readable(bob, C), C),
		show('lab:    who may read formula  ', policy(lab)::readers(formula, D), D),
		show('lockdown office: payroll      ', lockdown(office)::readers(payroll, E), E),
		show('lockdown office: report7      ', lockdown(office)::readers(report7, F), F),
		encapsulation.

	% The second argument is a goal, to be called in the caller's context.
	:- meta_predicate(show(*, 0, *)).
	show(Label, Goal, Answer) :-
		call(Goal),
		write(Label), write(Answer), nl.

	% grants/4 is protected, so a message from outside is refused.
	encapsulation :-
		catch(policy(office)::grants(bob, intern, payroll, secret), error(Error, _), true),
		write('calling a protected predicate : '), write(Error), nl.

:- end_object.
