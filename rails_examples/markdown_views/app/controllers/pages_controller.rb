# frozen_string_literal: true

class PagesController < ApplicationController
  include HighVoltage::StaticPage
  layout :layout_for_page
  before_action :extract_frontmatter

  # https://github.com/ruby/psych/issues/604
  ENGINES = {
    yaml: {
      parse: ->(yaml) { Psych.safe_load(yaml, permitted_classes: [Date, Time]) },
      stringify: ->(hash) { Psych.dump(hash).sub(/^---(\n|\s)?/, '') }
    }
  }.freeze

  private

  def extract_frontmatter
    @frontmatter = RubyMatter.parse(file_contents, engines: ENGINES).data
  end

  def file_contents
    File.read(File.join('app', 'views', "#{file}.html.md"))
  end

  def file
    page_finder_factory.new(params[:id]).find
  end

  def resource
    params[:id].split('/').first
  end

  def layout_for_page
    case resource
    when 'blog'
      'pages/blog_post'
    else
      'application'
    end
  end

  def page_finder_factory
    PageFinder
  end
end
