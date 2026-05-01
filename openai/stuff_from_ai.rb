# experiments/openai/stuff_from_ai.rb
#
# Using the OpenAI Assistant protocol
#

class StuffFromAI < ApplicationRecord
  attr_accessor :prompt

  belongs_to :user

  # the client polls to see when the assistant has responded by checking the status
  def status
    api_status = client.runs.retrieve(thread_id: thread_id, id: run_id)['status']
    api_status == 'completed' && practices.blank? ? 'no_results' : api_status
  end

  # returns the raw message from the assistant (once there is one)
  def message
    return @message if @message
    messages = client.messages.list(thread_id: thread_id)
    role = messages['data'][0]['role']

    return nil unless role == 'assistant'

    @message = messages['data'][0]['content'][0]['text']['value']
    @message
  end

  # This parses the message from the assistant which has been trained to return an array of strings as the response
  def stuff
    return nil if message.blank?
    practice_keys = nil
    matches = message.match(/\[(.*)\]/)
    practice_keys = matches[1].gsub(/[',]/, '').split if matches && matches[1]
    practice_keys
  end

  # this kicks off sending the message to the assistant
  def start_run!
    create_thread
    wait_for_thread_id
    add_message prompt
    create_run
  end

  private

  # i had to put this in there so it got the thread ID before trying to add the message
  def wait_for_thread_id
    attempts = 0
    while thread_id.blank? && attempts < 10
      sleep(0.1)
      attempts += 1
    end
  end

  def thread
    client.threads.retrieve(id: thread_id)
  end

  def run
    client.runs.retrieve(thread_id: thread_id, id: run_id)
  end

  def add_message(content)
    raise 'Missing thread ID' if thread_id.blank?
    client.messages.create(thread_id: thread_id, parameters: { role: 'user', content: content })
  end

  def client
    @client ||= OpenAI::Client.new
  end

  def create_run
    raise 'Missing thread ID' if thread_id.blank?
    @run =
      client.runs.create(
        thread_id: thread_id,
        parameters: {
          assistant_id: ENV['PRACTICES_RECOMMENDATION_ASSISTANT_ID']
        }
      )
    update(run_id: @run['id'])
  end

  def create_thread
    thread = client.threads.create
    update(thread_id: thread['id'])
  end
end
