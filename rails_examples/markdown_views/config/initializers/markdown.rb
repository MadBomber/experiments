module MarkdownHandler
  def self.erb
    @erb ||= ActionView::Template.registered_template_handler(:erb)
  end

  def self.call(template, source)
    parser = RubyMatter.parse(source)
    compiled_source = erb.call(template, parser.content)
    "Redcarpet::Markdown.new(Redcarpet::Render::HTML.new).render(begin;#{compiled_source};end).html_safe"
  end
end

ActionView::Template.register_template_handler :md, MarkdownHandler
