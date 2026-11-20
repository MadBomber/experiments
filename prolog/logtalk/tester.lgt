%  tester.lgt -- loads the application and runs its tests.
%
%    swilgt -g "logtalk_load(tester), halt"

:- initialization((
	set_logtalk_flag(report, warnings),
	logtalk_load(lgtunit(loader)),
	logtalk_load(policy),
	logtalk_load(tests, [hook(lgtunit)]),
	tests::run
)).
