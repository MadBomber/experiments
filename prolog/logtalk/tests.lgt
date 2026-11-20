%  tests.lgt -- unit tests using lgtunit, Logtalk's own test framework.

:- object(tests,
	extends(lgtunit)).

	test(clearance_grants_access, true) :-
		policy(office)::may_read(ann, report7).

	test(intern_is_denied_secret, fail) :-
		policy(office)::may_read(bob, payroll).

	test(owner_may_read, true) :-
		policy(office)::may_read(bob, report7).

	test(public_is_open_to_all, true(Users == [ann, bob, cy])) :-
		policy(office)::readers(wiki, Users).

	test(only_manager_reads_secret, true(Users == [cy])) :-
		policy(office)::readers(payroll, Users).

	test(same_policy_other_directory, true(Users == [eli])) :-
		policy(lab)::readers(formula, Users).

	test(undefined_declared_predicate_fails, fail) :-
		lab::owns(_, _).

	test(lockdown_closes_secret, true(Users == [])) :-
		lockdown(office)::readers(payroll, Users).

	test(lockdown_keeps_the_rest, true(Users == [ann, bob, cy])) :-
		lockdown(office)::readers(report7, Users).

	test(inherited_category_predicate, true(Docs == [report7, wiki])) :-
		lockdown(office)::readable(cy, Docs).

	test(protected_predicate_is_not_callable, error(permission_error(access, protected_predicate, grants/4))) :-
		policy(office)::grants(bob, intern, payroll, secret).

	test(conforms_to_protocol, true) :-
		conforms_to_protocol(lockdown(office), policyp).

:- end_object.
