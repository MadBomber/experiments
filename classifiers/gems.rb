require 'system_package' # from MadBomber/lib_ruby

source 'https://rubygems.org'

system_package 'catdoc'   if fedora? || mac?
#system_package 'gsl'      if fedora? || mac?  # ruby lib depends on old binary
system_package 'html2txt' if fedora? || mac?
system_package 'pdf2txt'  if fedora? || mac?
system_package 'sqlite3'  if fedora? || mac?


# Database stuff
gem 'activerecord'
gem 'pg'
gem 'rethinkdb'
gem 'nobrainer'

# Other data sources
gem 'spreadsheet' # used with lurn
gem 'mechanize'   # used with lurn


# Utilities

gem 'debug_me'
gem 'kick_the_tires'
gem 'amazing_print'
gem 'minitest'
gem 'cli_helper'

# web-based API
gem 'uclassify'

# bayesian classifiers

gem 'nbayes'
gem 'bayesball'       # this is nice
gem 'lurn'
gem 'omnicat-bayes'



# bayes and LSI
#gem 'rb-gsl'          # required for LSI in the reclassifier
gem 'reclassifier'
gem 'madeleine'       # object persistence; has not worked

gem 'classifier-reborn'  #, git: 'https://github.com/MadBomber/classifier-reborn.git'

#system_package 'gsl'  if fedora? || mac?
#gem 'gsl'  # might load its own gsl library

#gem 'stuff-classifier'  # bayes and tf-idf weights / depends on old sqlite3 version

gem 'summary'  # not any good.

# Support Vector Machines
gem "svm_helper"
gem "svmlab"
gem 'libsvm-ruby-swig'
gem 'libsvm_preprocessor'
gem 'libsvmffi'
gem 'rb-libsvm'
gem 'hoatzin'

#gem 'omnicat-svm' 	# out of sync with omnicat-bayes
                    # wants an older version of omnicat

system_package 'libsvm'  if fedora? || mac?


# Clustering

gem 'kmeans-clusterer'

gem 'fasttext'
