%  policy.lgt -- the access policy from ../portable/explain.pl, restructured
%  with the things Logtalk adds on top of Prolog:
%
%    protocol            an interface: predicates an object promises to answer
%    object              encapsulated predicates with public/protected/private scope
%    category            a mixin: reusable predicates imported into any object
%    parametric object   policy(Directory) works over any directory object
%    extends, ^^         inheritance with overriding and "super" calls
%    ::                  message sending, resolved in the receiver ("self")


% ------------------------------------------------------------ data sources

:- protocol(directoryp).

	:- public(role/2).
	:- public(classified/2).
	:- public(owns/2).

:- end_protocol.


:- object(office,
	implements(directoryp)).

	role(ann, engineer).
	role(bob, intern).
	role(cy,  manager).

	classified(wiki,    public).
	classified(report7, internal).
	classified(payroll, secret).

	owns(bob, report7).

:- end_object.


% lab defines no owns/2 clauses.  Because the protocol declares it, the
% message simply fails, where plain Prolog would raise an existence error.
:- object(lab,
	implements(directoryp)).

	role(dee, engineer).
	role(eli, manager).

	classified(notebook, internal).
	classified(formula,  secret).

:- end_object.


% ------------------------------------------------------------------ policy

:- protocol(policyp).

	:- public(may_read/2).

:- end_protocol.


% Reports that work for any object answering may_read/2.
:- category(reporting).

	:- public(readers/2).
	readers(Doc, Users) :-
		findall(User, ::may_read(User, Doc), Unsorted),
		sort(Unsorted, Users).

	:- public(readable/2).
	readable(User, Docs) :-
		findall(Doc, ::may_read(User, Doc), Unsorted),
		sort(Unsorted, Docs).

:- end_category.


:- object(policy(_Directory_),
	implements(policyp),
	imports(reporting)).

	may_read(User, Doc) :-
		_Directory_::role(User, Role),
		_Directory_::classified(Doc, Level),
		once(::grants(User, Role, Doc, Level)).

	% Descendants may redefine what grants access; nobody outside can call it.
	:- protected(grants/4).
	grants(_, _, _, public).
	grants(User, _, Doc, _) :-
		_Directory_::owns(User, Doc).
	grants(_, Role, _, Level) :-
		clearance(Role, Cleared),
		covers(Cleared, Level).

	% Undeclared predicates are local to the object.
	clearance(engineer, internal).
	clearance(manager,  secret).

	covers(Level, Level).
	covers(secret, internal).

:- end_object.


% During a lockdown, secret documents are closed to everyone but their owner.
:- object(lockdown(_Directory_),
	extends(policy(_Directory_))).

	grants(User, Role, Doc, Level) :-
		Level \== secret,
		^^grants(User, Role, Doc, Level).
	grants(User, _, Doc, secret) :-
		_Directory_::owns(User, Doc).

:- end_object.
