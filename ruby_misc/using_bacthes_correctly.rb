#!/usr/bin/env ruby
# Using_batches_correctly.rb
#
# See: https://blog.eq8.eu/til/update-millions-of-records-in-rails.html
#

# app/workers/update_addresses_worker.rb
class UpdateAddressesWorker
  include Sidekiq::Worker
  sidekiq_options queue: :manual

  def perform(min_id, max_id, batch_size = 1_000)
    Address
      .where(id: min_id..max_id)
      .in_batches(of: batch_size) do |address_batch|
        MyService.new.call(address_batch)
      end
  end
end



class MyService
  def call(address_batch)
    addresses = address_batch.map do |address|
      # some real business logic code here manipulating the address object state, this is just an example
      address.city.downcase!
      address.state.downcase!
      address
    end

    # `Model.import` is from activerecord-import gem
    ::Address.import(
      addresses,
      on_duplicate_key_update: {
        conflict_target: %i[id],
        validate: true,
        columns: [:city, :state]
      }
    )
  end
end
