# encoding: utf-8
# frozen_string_literal: true
##########################################################
###
##  File: scene_control_message.rb
##  Desc: SmartMessage for scene control commands
##

require 'smart_message'

class SceneControlMessage < SmartMessage::Base
  # Scene control messages for directing the actors
  #
  # @attr command [String] Control command (start, stop, pause, resume, end)
  # @attr scene [Integer] Scene number being controlled
  # @attr timestamp [Integer] Unix timestamp
  # @attr parameters [Hash] Optional additional parameters

  attribute :command,    String
  attribute :scene,      Integer
  attribute :timestamp,  Integer
  attribute :parameters, Hash, optional: true

  VALID_COMMANDS = %w[start stop pause resume end reset].freeze

  validates :command, presence: true, inclusion: { in: VALID_COMMANDS }
  validates :scene, presence: true

  # Publish this control message
  #
  # @param channel [String] Redis channel for control messages
  def publish(channel = 'writers_room:control')
    super(channel)
  end

  # Check if this is a specific command
  #
  # @param cmd [String] Command to check
  # @return [Boolean]
  def command?(cmd)
    command == cmd.to_s
  end

  # Start scene command
  def self.start_scene(scene_number, params = {})
    new(
      command: 'start',
      scene: scene_number,
      timestamp: Time.now.to_i,
      parameters: params
    )
  end

  # Stop scene command
  def self.stop_scene(scene_number)
    new(
      command: 'stop',
      scene: scene_number,
      timestamp: Time.now.to_i
    )
  end

  # End scene command (natural completion)
  def self.end_scene(scene_number)
    new(
      command: 'end',
      scene: scene_number,
      timestamp: Time.now.to_i
    )
  end
end
