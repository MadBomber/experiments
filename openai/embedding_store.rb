#!/usr/bin/env ruby -wKU
# openai/embedding_store.rb
# see: https://gist.github.com/peterc/b9723e648cd2fc95c2689dedf9c6b6d2

# gem install sqlite-vss -v 0.1.1.pre.alpha.20 --pre

# Example of using SQLite VSS with OpenAI's text embedding API
# from Ruby.

# Note: Install/bundle the sqlite3, sqlite_vss, and ruby-openai gems first
# OPENAI_API_KEY must also be set in the environment
# Other embeddings can be used, but this is the easiest for a quick demo

# More on the topic at
# https://observablehq.com/@asg017/introducing-sqlite-vss
# https://observablehq.com/@asg017/making-sqlite-extension-gem-installable

require 'json'
require 'openai'
require 'sqlite3'
require 'sqlite_vss'

class EmbeddingStore
  def initialize(filename = 'vst_test.db')
    @db = SQLite3::Database.new('vst_test.db')
    @db.results_as_hash = true
    @db.enable_load_extension(true)
    SqliteVss.load(@db)
    @db.enable_load_extension(false)

    @db.execute(%{create table if not exists docs ( doc text, e blob )})
    @db.execute(%{create unique index if not exists docs_doc on docs(doc)})
    @db.execute(%{create virtual table if not exists vss_docs using vss0( e(1536) )})

    @openai = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def get_embeddings(texts)
    texts = Array(texts)

    res = @openai.embeddings(parameters: { model: "text-embedding-ada-002", input: texts })

    res['data'].map { |r| r['embedding'] }
  end

  def store(text, embedding)
    @db.query(%{insert into docs (doc, e) values (?, ?) on conflict(doc) do update set e=excluded.e}, [text, embedding.to_json])
  end

  def reindex
    @db.execute(%{delete from vss_docs})
    @db.execute(%{insert into vss_docs (rowid, e) select rowid, e from docs})
  end

  def search(query)
    query_embedding = get_embeddings(query).first.to_json
    
    @db.query(%{
      with matches as (
        select rowid, distance
        from vss_docs
        where vss_search(
          e, vss_search_params(?, 2)
        )
      )
      select
        docs.doc, matches.distance
      from matches
      left join docs on docs.rowid = matches.rowid}, query_embedding)
  end
end


texts = [
  "Ruby is a programming language",
  "Bananas taste fantastic",
  "I could really go for a mango smoothie right now",
  "Python is a way to build computer programs",
  "One of the earliest programming languages was Fortran",
  "Is Ruby better than Python for webapps?",
  "Rails was created by David Heinemeier Hansson"
]

es = EmbeddingStore.new

embeddings = es.get_embeddings(texts)

texts.zip(embeddings).each do |text, embedding|
  es.store(text, embedding)
end

es.reindex

queries = [
  'I love programming in Ruby!',
  'Bring me some fruit',
  'He was born in Denmark'
]

queries.each do |query|
  puts "Top results for #{query}"
  es.search(query).each { |r| p r }
  puts "-----"
end


# Top results for I love programming in Ruby!
# {"doc"=>"Ruby is a programming language", "distance"=>0.15872865915298462}
# {"doc"=>"Is Ruby better than Python for webapps?", "distance"=>0.2929407060146332}
# -----
# Top results for Bring me some fruit
# {"doc"=>"I could really go for a mango smoothie right now", "distance"=>0.308392196893692}
# {"doc"=>"Bananas taste fantastic", "distance"=>0.33153215050697327}
# -----
# Top results for He was born in Denmark
# {"doc"=>"Rails was created by David Heinemeier Hansson", "distance"=>0.45908668637275696}
# {"doc"=>"One of the earliest programming languages was Fortran", "distance"=>0.4846964180469513}
# -----

