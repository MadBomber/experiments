# The Commander class handles commands and manages muted channels and users.
class Commander
  # Initializes a new instance of the Commander class.
  #
  # @param session [Bunny::Session] The Bunny session object.
  def initialize(session)
    @channels = session.queues.map(&:name)
    @users = []
    @muted_channels = []
    @muted_users = []
    @exchange = session.exchange("chat")
  end


  # Processes a message and executes the corresponding command.
  #
  # @param message [Bunny::Message] The message to process.
  # @return [Boolean] True if the message was a command, false otherwise.
  def process(message)
    if message[:payload].start_with?("/")
      command, *params = message[:payload].split(" ")
      method_name = command[1..-1]
      if respond_to?(method_name)
        send(method_name, *params)
      else
        puts "Unknown command: #{command}"
      end
      return true
    else
      username = message[:headers]["username"]
      @users << username unless @users.include?(username)
      return false
    end
  end


  # Mutes one or more channels and/or users.
  #
  # @param params [Array<String>] The list of channels and/or users to mute.
  def mute(*params)
    channels, users = split_params(params)
    channels.each do |channel|
      if @channels.include?(channel) && !@muted_channels.include?(channel)
        @muted_channels << channel
        puts "Muted channel #{channel}"
      end
    end
    users.each do |user|
      unless @muted_users.include?(user)
        @muted_users << user
        puts "Muted user #{user}"
      end
    end
  end

  # Unmutes one or more channels and/or users.
  #
  # @param params [Array<String>] The list of channels and/or users to unmute.
  def unmute(*params)
    channels, users = split_params(params)
    channels.each do |channel|
      if @channels.include?(channel) && @muted_channels.include?(channel)
        @muted_channels.delete(channel)
        puts "Unmuted channel #{channel}"
      end
    end
    users.each do |user|
      if @muted_users.include?(user)
        @muted_users.delete(user)
        puts "Unmuted user #{user}"
      end
    end
  end

  # Lists all channels and their mute status.
  #
  # @param params [Array<String>] Unused.
  def channels(*params)
    puts "Channels:"
    @channels.each do |channel|
      muted = @muted_channels.include?(channel)
      puts "#{channel}#{muted ? " (muted)" : ""}"
    end
  end

  # Lists all users and their mute status.
  #
  # @param params [Array<String>] Unused.
  def users(*params)
    puts "Users:"
    @users.each do |user|
      muted = @muted_users.include?(user)
      puts "#{user}#{muted ? " (muted)" : ""}"
    end
  end

  private

  # Splits the parameters into channels and users.
  #
  # @param params [Array<String>] The list of parameters to split.
  # @return [Array<Array<String>>] The list of channels and users.
  def split_params(params)
    channels = params.select { |param| param.start_with?("#") }.map { |param| param[1..-1] }
    users = params.select { |param| param.start_with?("@") }.map { |param| param[1..-1] }
    return channels, users
  end
end

__END__

  # Subscribes the user to a list of channels.
  #
  # @param channels [Array<String>] The list of channels to subscribe to.
  def subscribe(channels)
    channels.each do |channel|
      queue_name = "#{@username}-#{channel}"
      queue = @session.queue(queue_name)
      if queue.exists?
        queue.bind(@exchange, routing_key: "#{channel}.*")
        @subscriptions[channel] = queue_name
      else
        print "The #{channel} channel does not exist. Do you want to create it? (y/n) "
        answer = gets.chomp.downcase
        if answer == "y"
          queue = @session.queue(queue_name)
          queue.bind(@exchange, routing_key: "#{channel}.*")
          @subscriptions[channel] = queue_name
        end
      end
    end
  end

  # Unsubscribes the user from a list of channels.
  #
  # @param channels [Array<String>] The list of channels to unsubscribe from.
  def unsubscribe(channels)
    channels.each do |channel|
      queue_name = @subscriptions[channel]
      if queue_name
        queue = @session.queue(queue_name)
        if queue.exists?
          queue.unbind(@exchange, routing_key: "#{channel}.*")
          @subscriptions.delete(channel)
        else
          puts "The #{channel} channel does not exist."
        end
      end
    end
  end


