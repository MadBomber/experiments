
class SearchController < ApplicationController
  def search
    if params[:term].nil?
      @articles = []
    else
      @articles = Article.search params[:term]
    end
  end
end