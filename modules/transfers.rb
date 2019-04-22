def transfers
  transfers_rss = RSS::Parser.parse('http://www.sport-express.ru/services/materials/news/transfers/se/')
  transfers = []
  transfers_rss.items[0..10].each do |item|
    title = "*#{item.title}*"
    description = "`#{item.description}`"
    link = "[Полная статья](#{item.link})"
    transfers << [title, description, link]
  end
  transfers.map { |a, s, d| [ a, s, ["#{d}\n"] ] }*"\n "
  rescue => e
    "There are no `transfers` list for today now, we will update it soon! / You can check #{'http://www.sport-express.ru/football/transfers/'} at this time."
end
