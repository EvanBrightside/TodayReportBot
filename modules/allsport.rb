module Allsport
  module_function

  def call
    url = 'http://www.sport-express.ru/services/materials/news/se/'
    if HTTParty.get(url).code == 200
      rss = RSS::Parser.parse(url)
      allsport_rss = rss.items.select { |a| a.category.content != "Футбол - Трансферы"}
      allsport = []
      allsport_rss[0..10].each do |item|
        category = "*#{item.category.content.upcase}*"
        title = "_#{item.title}_"
        description = "`#{item.description}`"
        link = "[Полная статья](#{item.link})"
        allsport << [category, title, description, link]
      end
      allsport.map { |a, s, d, f| [a, s, d, ["#{f}\n "]] }.join("\n")
    else
      sp_url = 'https://youtu.be/ww4pgZWOkqY'
      "Spartak! #{sp_url}"
    end
  rescue StandardError
    'Not avaliable now / telegram stuff, nothing to worry!'
  end
end
