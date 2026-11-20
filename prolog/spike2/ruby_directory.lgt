%  ruby_directory.lgt -- a directory whose facts live in the host Ruby program.
%
%  It implements the same protocol as office and lab in ../logtalk/policy.lgt,
%  so policy(ruby_directory) works unchanged.  The {}/1 control construct
%  calls a plain Prolog predicate; here those predicates are Ruby blocks
%  registered through Swipl::Engine#relation.

:- object(ruby_directory,
	implements(directoryp)).

	role(User, Role) :-
		{ruby_role(User, Role)}.

	classified(Doc, Level) :-
		{ruby_classified(Doc, Level)}.

	owns(User, Doc) :-
		{ruby_owns(User, Doc)}.

:- end_object.
