require 'csv'
require 'pry'
require 'pg'

def db_connection
  begin
    connection = PG.connect(dbname: "news_aggregator_development")
    yield(connection)
  ensure
    connection.close
  end
end

csv_records = CSV.readlines('articles.csv', headers: true)

sql = 'INSERT INTO articles (title, url, description) VALUES($1, $2, $3)'
csv_records.each do |article|
  db_connection do |conn|
    result = conn.exec_params(
      'SELECT title FROM articles WHERE title=$1',
      [article["title"]]
    )
    if result.to_a.empty?
      conn.exec_params(sql, [article["title"], article["url"], article["description"]])
    end
  end
end
