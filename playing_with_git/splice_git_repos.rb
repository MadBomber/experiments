#!/usr/bin/env ruby
##################################################
###
##  File: splice_git_repos.rb
##  Desc: Splice and external git repo onto a base git repo from which it was once extracted
#
=begin

       git-commit - Record changes to the repository

SYNOPSIS
       git commit [-a | --interactive | --patch] [-s] [-v] [-u<mode>] [--amend]
                  [--dry-run] [(-c | -C | --fixup | --squash) <commit>]
                  [-F <file> | -m <msg>] [--reset-author] [--allow-empty]
                  [--allow-empty-message] [--no-verify] [-e] [--author=<author>]
                  [--date=<date>] [--cleanup=<mode>] [--[no-]status]
                  [-i | -o] [-S[<keyid>]] [--] [<file>...]

       The --dry-run option can be used to obtain a summary of what is included by any of
       the above for the next commit by giving the same set of parameters (options and
       paths).

       -F <file>, --file=<file>
           Take the commit message from the given file. Use - to read the message from
           the standard input.

       --author=<author>
           Override the commit author. Specify an explicit author using the standard A U
           Thor <author@example.com> format. Otherwise <author> is assumed to be a
           pattern and is used to search for an existing commit by that author (i.e.
           rev-list --all -i --author=<author>); the commit author is then copied from
           the first such commit found.

       --date=<date>
           Override the author date used in the commit.


Here is the sequence:
1. create a new branch (splice) on the base repo master branch
2. in the working directory of splice remove everything except the .git directory
3. in the external working directory checkout the next commit
4. copy everything (except the .git directory) from the external wd to the splice wd
5. add everything in splice wd (except .git) to the current index
6. create a git commit command using the git info from the external wd; use author, date and message from external
7. do the git commit command and return to step #2 unless there are no more commits to be made


=end
#

require 'debug_me'
include DebugMe

require 'kick_the_tires'

require 'awesome_print'

require 'logger'

require 'git'


Git.configure do |config|
  # If you want to use a custom git binary
  config.binary_path = '/usr/local/bin/git'

  # If you need to use a custom SSH script
  #config.git_ssh = '/path/to/ssh/script'
end


working_dir = Pathname.pwd.parent.to_s

#debug_me {[ :working_dir ]}

g = Git.open(working_dir, :log => Logger.new(STDOUT))

ap g.methods


repo_log        = g.log(100_000)   # parameter is the maximum number of log entries to return
repo_log_first  = repo_log.first
repo_log_last   = repo_log.last

# ap repo_log_first.methods

debug_me("FIRST") {%w[
  repo_log_first.date
  repo_log_first.sha
  repo_log_first.author.date
  repo_log_first.author.name
  repo_log_first.author.email
  repo_log_first.committer.date
  repo_log_first.committer.name
  repo_log_first.committer.email
  repo_log_first.message
  repo_log_first.contents_array
]}


debug_me("LAST") {%w[
  repo_log_last.date
  repo_log_last.sha
  repo_log_last.author.date
  repo_log_last.author.name
  repo_log_last.author.email
  repo_log_last.committer.date
  repo_log_last.committer.name
  repo_log_last.committer.email
  repo_log_last.message
  repo_log_last.contents_array
]}

commit = g.gcommit(repo_log_last.sha)

ap commit.methods

debug_me("LAST") {%w[
  commit.date
  commit.sha
  commit.author.date
  commit.author.name
  commit.author.email
  commit.committer.date
  commit.committer.name
  commit.committer.email
  commit.message
  commit.contents_array
]}


repo_log.reverse_each do |entry|
  puts entry.date
end

__END__

debug_me {[
  'g.index',
  'g.index.readable?',
  'g.index.writable?',
  'g.repo',
  'g.dir'
]}

puts
puts "="*54
puts "== playing with log"
puts

repo_log        = g.log
repo_log_first  = repo_log.first
repo_log_last   = repo_log.last


debug_me {[ "repo_log.class", "repo_log.first", "repo_log.last", "repo_log" ]}



__END__

debug_me {[

  "g.log",   # returns array of Git::Commit objects
  "g.log.since('2 weeks ago')",
  "g.log.between('v2.5', 'v2.6')",
  "g.log.each {|l| puts l.sha }",
  "g.gblob('v2.5:Makefile').log.since('2 weeks ago')",

]}




g.object('HEAD^').to_s  # git show / git rev-parse
g.object('HEAD^').contents
g.object('v2.5:Makefile').size
g.object('v2.5:Makefile').sha

g.gtree(treeish)
g.gblob(treeish)
g.gcommit(treeish)


commit = g.gcommit('1cc8667014381')

commit.gtree
commit.parent.sha
commit.parents.size
commit.author.name
commit.author.email
commit.author.date.strftime("%m-%d-%y")
commit.committer.name
commit.date.strftime("%m-%d-%y")
commit.message

tree = g.gtree("HEAD^{tree}")

tree.blobs
tree.subtrees
tree.children # blobs and subtrees

g.revparse('v2.5:Makefile')

g.branches # returns Git::Branch objects
g.branches.local
g.branches.remote
g.branches[:master].gcommit
g.branches['origin/master'].gcommit

g.grep('hello')  # implies HEAD
g.blob('v2.5:Makefile').grep('hello')
g.tag('v2.5').grep('hello', 'docs/')
g.describe()
g.describe('0djf2aa')
g.describe('HEAD', {:all => true, :tags => true})

g.diff(commit1, commit2).size
g.diff(commit1, commit2).stats
g.diff(commit1, commit2).name_status
g.gtree('v2.5').diff('v2.6').insertions
g.diff('gitsearch1', 'v2.5').path('lib/')
g.diff('gitsearch1', @git.gtree('v2.5'))
g.diff('gitsearch1', 'v2.5').path('docs/').patch
g.gtree('v2.5').diff('v2.6').patch

g.gtree('v2.5').diff('v2.6').each do |file_diff|
   puts file_diff.path
   puts file_diff.patch
   puts file_diff.blob(:src).contents
end

g.config('user.name')  # returns 'Scott Chacon'
g.config # returns whole config hash

g.tags # returns array of Git::Tag objects

g.show()
g.show('HEAD')
g.show('v2.8', 'README.md')

Git.ls_remote('https://github.com/schacon/ruby-git.git') # returns a hash containing the available references of the repo.
Git.ls_remote('/path/to/local/repo')
Git.ls_remote() # same as Git.ls_remote('.')
