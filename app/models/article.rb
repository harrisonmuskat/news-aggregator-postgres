require "pg"
require "uri"

class Article
  attr_reader :title, :url, :description, :errors

  def initialize(article_hash = nil)
    if !article_hash.nil?
      @title = article_hash["title"]
      @url = article_hash["url"]
      @description = article_hash["description"]
      @errors = []
    end
  end

  def self.all
    article_list = nil
    db_connection do |conn|
      article_list = conn.exec('SELECT articles.title, articles.url, articles.description FROM articles')
    end
    article_list = article_list.map do |article|
      Article.new(article)
    end
    return article_list
  end

  def save
    if self.valid?
      db_connection do |conn|
        conn.exec_params(
          "INSERT INTO articles (title, url, description) VALUES($1, $2, $3)",
          [@title, @url, @description]
        )
      end
      return true
    end
    false
  end

  def db_connection
    begin
      connection = PG.connect(dbname: "news_aggregator_test")
      yield(connection)
    ensure
      connection.close
    end
  end

  def valid?
    self.blank_attributes
    self.invalid_url
    self.too_short_description
    self.url_already_exists
    @errors.empty?
  end

  def blank_attributes
    if @title == "" || @url == "" || @description == ""
      @errors << "Please completely fill out form"
    end
  end

  def invalid_url
    if URI.regexp.match(@url).nil? && @url != ""
      @errors << "Invalid URL"
    end
  end

  def too_short_description
    if @description.length < 20 && @description != ""
      @errors << "Description must be at least 20 characters long"
    end
  end

  def url_already_exists
    Article.all.each do |article|
      if @url == article.url
        @errors << "Article with same url already submitted"
      end
    end
  end
end
