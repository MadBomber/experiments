#!/usr/bin/env ruby
# sandbox/git_repo/misc/chatbot/catgpt.rb
#
# See: https://andymaleh.blogspot.com/2023/03/chatgpt-materialized-as-gui-via-ruby.html
#



require 'glimmer-dsl-libui'
require 'ruby/openai'

class ChatGPT

  ###########################################
  class Message < Struct.new(:role, :content)
    
    def role_color
      [role, color]
    end

    def content_color
      [content, color]
    end

    def color
      case role
      when 'System' then :gray
      when 'Human' then :green
      when 'CatGPT' then :brown
      else raise
      end
    end
  end


  ############################################
  attr_reader :history

  def initialize
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_ACCESS_TOKEN'])
    @history = [Message.new('System', 'Act like a cat')]
    call('Hi gpt 3.5 turbo!')
  end

  def call(query_text)
    res = @client.chat(
      parameters: {
        model: 'gpt-3.5-turbo',
        messages: generate_message(query_text)
      }
    )
    str = res.dig('choices', 0, 'message', 'content')
    history << Message.new('Human', query_text)
    history << Message.new('CatGPT', str)
  end

  def generate_message(query_text)
    m = history.map do |m|
      case m.role
      when 'CatGPT'
        { 'role' => 'assistant', 'content' => m.content }
      when 'Human'
        { 'role' => 'user', 'content' => m.content }
      when 'System'
        { 'role' => 'system', 'content' => m.content }
      end
    end
    m.push({ 'role' => 'user', 'content' => query_text })
    p m
  end
end


###############################################
class Chat
  include Glimmer

  attr_accessor :entry_text

  def initialize
    @chatgpt = ChatGPT.new
  end

  def launch
    window('CatGPT - Glimmer DSL LibUI', 400, 400) do
      vertical_box do
        table do
          text_color_column('role')
          text_color_column('content')
          cell_rows <=> [@chatgpt, :history,
                         { column_attributes: { 'role' => :role_color, 'content' => :content_color } }]
        end

        horizontal_box do
          stretchy false

          entry do
            text <=> [self, :entry_text]
          end

          button('GO') do
            stretchy false
            on_clicked do
              @chatgpt.call(entry_text)
            end
          end
        end
      end

    end.show
  end
end

Chat.new.launch
