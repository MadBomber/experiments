require 'net/imap'
require 'mail'

class GmailReader
  include Enumerable

  IMAP_HOST = 'imap.gmail.com'
  IMAP_PORT = 993
  FETCH_ATTRS = ['BODY.PEEK[]', 'FLAGS', 'ENVELOPE'].freeze

  attr_reader :email, :mailbox, :search_criteria

  def initialize(
    email:           ENV['GMAIL_ADDRESS'],
    password:        ENV['GMAIL_APP_PASSWORD'],
    mailbox:         'INBOX',
    search_criteria: ['UNSEEN']
  )
    @email           = email
    @password        = password
    @mailbox         = mailbox
    @search_criteria = search_criteria

    raise ArgumentError, "email is required (set GMAIL_ADDRESS env var)" unless @email
    raise ArgumentError, "password is required (set GMAIL_APP_PASSWORD env var)" unless @password
  end

  def each(&block)
    return enum_for(:each) unless block_given?

    connect do |imap|
      ids = imap.search(@search_criteria)
      ids.reverse_each do |id|
        msg = imap.fetch(id, FETCH_ATTRS)&.first
        next unless msg

        yield build_message(msg)
      end
    end
  end

  def count
    connect do |imap|
      imap.search(@search_criteria).length
    end
  end

  private

  def connect
    imap = Net::IMAP.new(IMAP_HOST, port: IMAP_PORT, ssl: true)
    imap.login(@email, @password)
    imap.examine(@mailbox)
    yield imap
  ensure
    imap&.logout rescue nil
    imap&.disconnect rescue nil
  end

  def build_message(msg)
    raw      = msg.attr['BODY[]']
    envelope = msg.attr['ENVELOPE']
    flags    = msg.attr['FLAGS']
    parsed   = Mail.new(raw)

    Message.new(
      message_id: envelope.message_id,
      date:       parsed.date,
      from:       parsed.from || [],
      to:         parsed.to || [],
      cc:         parsed.cc || [],
      subject:    parsed.subject,
      flags:      flags,
      body:       parsed,
      raw:        raw
    )
  end

  Message = Struct.new(
    :message_id, :date, :from, :to, :cc,
    :subject, :flags, :body, :raw,
    keyword_init: true
  ) do
    def text_plain
      return body.decoded unless body.multipart?

      find_part('text/plain')&.decoded
    end

    def text_html
      return nil unless body.multipart?

      find_part('text/html')&.decoded
    end

    def attachments
      body.attachments
    end

    def multipart?
      body.multipart?
    end

    def parts
      body.parts
    end

    def to_s
      <<~TEXT
        ======================================================
        Message ID: #{message_id}
        Date:       #{date}
        From:       #{from.join(', ')}
        To:         #{to.join(', ')}
        CC:         #{cc.empty? ? '(none)' : cc.join(', ')}
        Subject:    #{subject}
        Flags:      #{flags.join(', ')}
        ======================================================
      TEXT
    end

    private

    def find_part(content_type)
      find_in_parts(body.parts, content_type)
    end

    def find_in_parts(parts, content_type)
      parts.each do |part|
        return part if part.content_type&.start_with?(content_type)

        if part.content_type&.start_with?('multipart/')
          found = find_in_parts(part.parts, content_type)
          return found if found
        end
      end
      nil
    end
  end
end
