require "sinatra"
require "sinatra/activerecord"
require "pg"
require "csv"
require "uri"
require_relative "./app/models/article"

set :bind, '0.0.0.0'  # bind to all interfaces
set :views, File.join(File.dirname(__FILE__), "app", "views")

configure :development do
  set :db_config, { dbname: "news_aggregator_development" }
end

configure :test do
  set :db_config, { dbname: "news_aggregator_test" }
end

def db_connection
  begin
    connection = PG.connect(Sinatra::Application.db_config)
    yield(connection)
  ensure
    connection.close
  end
end

# Put your News Aggregator server.rb route code here
get '/' do
  db_connection do |conn|
    @article_list = conn.exec(
      'SELECT articles.title, articles.url, articles.description FROM articles'
    )
  end
  erb :index
end

get '/articles/new' do
  erb :new
end

post '/articles/new' do
  article_details = params.values
  sql = "INSERT INTO articles (title, url, description) VALUES($1, $2, $3)"
  db_connection do |conn|
    conn.exec_params(
      sql, [article_details[0], article_details[1], article_details[2]]
    )
  end

  redirect '/articles'
end

get '/articles' do
  db_connection do |conn|
    @article_list = conn.exec(
      'SELECT articles.title, articles.url, articles.description FROM articles'
    )
  end
  erb :index
end
