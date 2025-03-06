# src/transaction.rb

require 'json'
require 'time'

class Transaction
  FILE_PATH = 'transactions.json'

  class << self
    def log(transaction_data)
      unless transaction_data.is_a?(Hash)
        raise ArgumentError, 'Expected a hash as input'
      end

      transaction_data[:timestamp] = Time.now.utc.iso8601

      transactions = load_transactions
      transactions << transaction_data
      save_transactions(transactions)
    end

    private

    def load_transactions
      if File.exist?(FILE_PATH)
        file_content = File.read(FILE_PATH)
        JSON.parse(file_content, symbolize_names: true)
      else
        []
      end
    rescue JSON::ParserError
      []
    end

    def save_transactions(transactions)
      File.open(FILE_PATH, 'w') do |file|
        file.write(JSON.pretty_generate(transactions))
      end
    end
  end
end
