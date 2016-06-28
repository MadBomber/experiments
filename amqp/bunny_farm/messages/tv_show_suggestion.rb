# tv_show_suggestion.rb

# TODO: field validations

class TvShowSuggestion < BunnyFarm::Message

  fields :tv_show_name, :suggestion,
    { author: [ :name, :mailing_address, :email_address, :phone_number ]}

  actions :action

  # Handles the routing key: TvShowSuggestion.action.#
  # If there is anything after 'submit' element they are
  # considered parameters into the action.
  def action(params=[])
    # TODO: anything you want.
    save_suggestion
    notify_writers  if success?
    success? ? send_thank_you : send_sorry_please_try_again
    #success!
    # some_super_class_service
    successful? # true will ACK the message; false will not
  end

  private

  def save_suggestion
    puts "\nSAVING: " + @items[:suggestion]
    success
  end

  def notify_writers
    puts "Hey slackers! what about #{@items[:suggestion]}"
    rand(2) > 0 ? failure('Writers were sleeping') : success
  end

  def send_thank_you
    puts "Thank you goes to #{@items[:author][:name]}"
    success
  end

  def send_sorry_please_try_again
    reason = "Sorry #{@items[:author][:name]}, please try again later."
    STDERR.puts reason
    failure reason
  end
end # class TvShowSuggestion < BunnyFarmMessage
