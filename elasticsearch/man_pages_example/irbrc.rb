# irbrc.rb  sumlink this file as .irbrc
# brew install elasticsearch

require 'elasticsearch'
require 'ruby-progressbar'
require 'awesome_print'

def connect
  @client = Elasticsearch::Client.new(
    host: 'localhost',
    port: '9200'
  )
end


def es_client
  @client ||= connect
end


def status
  es_client.cluster.health
end


def create_index
  es_client.indices.create(
    {
      index: 'elastic_manpages',
      body: {
        mappings: {
          document: {
            properties: {
              command: {
                type: :text
              },
              description: {
                type:     :text,
                analyzer: :english
              },
              manpage: {
                type:     :text,
                analyzer: :english
              }
            }
          }
        }
      }
    }
  )
end


def insert_entry(command, description, manpage)
    es_client.index(
      {
        index:  'elastic_manpages',
        type:   :document,
        body: {
          command:      command,
          description:  description,
          manpage:      manpage
        }
      }
    )
end

def load_data
  apropos_regex   = /(?<cmds>.*)\(.*\).*-\s*(?<desc>.*)/ # MacOS
  all_pages       = `apropos .`.split("\n")
  all_pages_count = all_pages.size

  progressbar = ProgressBar.create(
                  {
                    title:  'ManPages',
                    total:  all_pages_count,
                    format: '%t: [%B] %c/%C %j%% %e',
                    output: STDERR
                  }
                )

  all_pages.each do |a_line|
    progressbar.increment

    matches     = apropos_regex.match a_line

    if matches.nil?
      puts "ERROR: #{a_line}"
      next
    end

    cmds        = matches[:cmds]
    description = matches[:desc]

    if cmds.include?(', ')
      cmds = cmds.split(', ').map{|c| c.split('(').first}
    end

    Array(cmds).each_with_index do |command, x|
      manpage = `man #{command}`unless x>0
      insert_entry(command, description, manpage)
    end
  end

  progressbar.finish
end


def search(term)
  result = es_client.search(
    {
      index: 'elastic_manpages',
      size: 10,
      body: {
        query: {
          multi_match: {
            query:            term,
            type:             :cross_fields,
            fields:           ['command', 'description^3', 'manpage^3'],
            operator:         :or,
            tie_breaker:      1.0,
            cutoff_frequency: 0.1
          }
        }
      }
    }
  )

  result['hits']['hits'].map do |hit|
    {
      command:      hit['_source']['command'],
      description:  hit['_source']['description'],
      manpage:      hit['_source']['manpage']
    }
  end
end

if $0 == __FILE__
  ap status
  ap load_data
  ap search('change image')
end
