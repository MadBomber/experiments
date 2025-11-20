# encoding: utf-8
# frozen_string_literal: true
##########################################################
###
##  File: stage_direction_message.rb
##  Desc: SmartMessage for stage directions and actions
##

require 'smart_message'

class StageDirectionMessage < SmartMessage::Base
  # Stage directions describing non-dialog actions
  #
  # @attr character [String] Character performing the action
  # @attr action [String] Description of the action
  # @attr scene [Integer] Scene number
  # @attr timestamp [Integer] Unix timestamp
  # @attr beat [String] Optional - which beat of the scene this belongs to

  attribute :character, String
  attribute :action,    String
  attribute :scene,     Integer
  attribute :timestamp, Integer
  attribute :beat,      String, optional: true

  validates :character, presence: true
  validates :action, presence: true
  validates :scene, presence: true

  # Publish this stage direction
  #
  # @param channel [String] Redis channel
  def publish(channel = 'writers_room:stage_directions')
    super(channel)
  end

  # Format as traditional stage direction
  #
  # @return [String]
  def to_stage_direction
    "[#{character.upcase} #{action}]"
  end
end
