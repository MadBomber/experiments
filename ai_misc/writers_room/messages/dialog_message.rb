# encoding: utf-8
# frozen_string_literal: true
##########################################################
###
##  File: dialog_message.rb
##  Desc: SmartMessage for character dialog
##

require 'smart_message'

class DialogMessage < SmartMessage::Base
  # Character dialog message for the writers room
  #
  # @attr from [String] Character name who is speaking
  # @attr content [String] The dialog line being spoken
  # @attr scene [Integer] Scene number
  # @attr timestamp [Integer] Unix timestamp when spoken
  # @attr emotion [String] Optional emotional tone (happy, sad, angry, nervous, etc.)
  # @attr addressing [String] Optional - character name being addressed

  attribute :from,       String
  attribute :content,    String
  attribute :scene,      Integer
  attribute :timestamp,  Integer
  attribute :emotion,    String,  optional: true
  attribute :addressing, String,  optional: true

  validates :from, presence: true
  validates :content, presence: true
  validates :scene, presence: true

  # Publish this dialog to the writers room channel
  #
  # @param channel [String] Redis channel to publish to
  def publish(channel = 'writers_room:dialog')
    super(channel)
  end

  # Check if this dialog is addressing a specific character
  #
  # @param character_name [String] Name to check
  # @return [Boolean]
  def addressing?(character_name)
    return true if addressing == character_name
    return true if content.include?(character_name)
    false
  end
end
