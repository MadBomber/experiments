# encoding: utf-8
# frozen_string_literal: true
##########################################################
###
##  File: meta_message.rb
##  Desc: SmartMessage for meta-commentary and analysis
##

require 'smart_message'

class MetaMessage < SmartMessage::Base
  # Meta messages for commentary, analysis, or system information
  #
  # @attr message_type [String] Type of meta message (analysis, commentary, system, error)
  # @attr content [String] The meta content
  # @attr scene [Integer] Scene number (optional)
  # @attr timestamp [Integer] Unix timestamp
  # @attr source [String] Source of the meta message (director, system, analyst, etc.)

  attribute :message_type, String
  attribute :content,      String
  attribute :scene,        Integer, optional: true
  attribute :timestamp,    Integer
  attribute :source,       String

  VALID_TYPES = %w[analysis commentary system error debug].freeze

  validates :message_type, presence: true, inclusion: { in: VALID_TYPES }
  validates :content, presence: true
  validates :source, presence: true

  # Publish this meta message
  #
  # @param channel [String] Redis channel
  def publish(channel = 'writers_room:meta')
    super(channel)
  end

  # Create an analysis message
  def self.analysis(content, scene: nil, source: 'system')
    new(
      message_type: 'analysis',
      content: content,
      scene: scene,
      timestamp: Time.now.to_i,
      source: source
    )
  end

  # Create a system message
  def self.system(content, scene: nil)
    new(
      message_type: 'system',
      content: content,
      scene: scene,
      timestamp: Time.now.to_i,
      source: 'system'
    )
  end

  # Create an error message
  def self.error(content, scene: nil, source: 'system')
    new(
      message_type: 'error',
      content: content,
      scene: scene,
      timestamp: Time.now.to_i,
      source: source
    )
  end
end
