%  loader.lgt -- loads the application.
%
%    swilgt -g "logtalk_load(loader), demo::run, halt"

:- initialization(
	logtalk_load([policy, demo])
).
