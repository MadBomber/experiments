# git_diff.rb

module Aicommit
  class GitDiff
    def initialize(dir:, commit_hash: nil, amend: false)
      @dir = dir
      @commit_hash = commit_hash
      @amend = amend
    end

    def generate_diff
      if @commit_hash.nil?
        `git -C #{@dir} diff --cached`
      else
        if @amend
          `git -C #{@dir} diff --cached #{@commit_hash}^`
        else
          `git -C #{@dir} diff #{@commit_hash}^ #{@commit_hash}`
        end
      end
    end
  end
end
