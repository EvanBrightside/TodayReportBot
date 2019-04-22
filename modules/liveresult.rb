def live
  url = 'https://www.liveresult.ru/football/matches/rss'
  begin
    if HTTParty.get(url).code == 200
      rss = RSS::Parser.parse(url)
      liga = %w[ Россия Италия Англия Германия Испания Франция Лига Международный
                 Товарищеские Европы Мира ЧМ-2018 ].join('|')
      soccer_rss = rss.items.select do |a|
        a.category.content =~ /#{liga}/ && a.pubDate.strftime('%d/%m/%Y') == Date.today.strftime('%d/%m/%Y')
      end
      soccerlive = [] unless soccer_rss.empty?
      soccer_rss.first(25).each do |item|
        category = item.category.content.upcase
        title = item.title
        date = item.pubDate.strftime('%d/%m/%Y - %H:%M')
        mobile_link = item.link.gsub("https://www.liveresult.ru/football/matches", "https://m.liveresult.ru/football/match")
        link = "[Ссылка на текстовую трансляцию](#{mobile_link})"
        soccerlive << [category, title, date, link]
      end
      live = soccerlive.map { |a, s, d, f| [ "*#{a}*", "`#{s}`", "`#{d}`", ["#{f}\n"] ] }*"\n"
    else
      sp_url = 'https://youtu.be/ww4pgZWOkqY'
      # Launchy.open sp_url
      "Spartak! #{sp_url}"
    end
  rescue => e
    "There are no `live` list for today now, we will update it soon! / At this time you can check #{'https://www.liveresult.ru/'}"
  end
end
