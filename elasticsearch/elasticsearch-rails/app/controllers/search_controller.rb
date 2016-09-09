
class SearchController < ApplicationController
  def search
    if params[:term].nil?
      @articles = []
    else
      term = params[:term]
      @articles = Article.search term, fields: [:text], highlight:  true
    end
  end

  def typeahead
    render json: Article.search(params[:term], {
      fields: ["title"],
      limit: 10,
      load: false,
      misspellings: {below: 5},
    }).map do |article| { title: article.title, value: article.id } end
  end

end

