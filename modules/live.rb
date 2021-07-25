module Live
  module_function

  def call
    url = 'https://www.liveresult.ru/football/matches/rss'
    if HTTParty.get(url).code == 200
      rss = RSS::Parser.parse(url)
      soccer_rss = rss.items.select do |a|
        liga = a.category.content&.downcase !~ /#{exclude_ligas.downcase}/
        current_date = a.pubDate.strftime('%d/%m/%Y') == Date.today.strftime('%d/%m/%Y')
        liga && current_date
      end
      soccerlive = [] unless soccer_rss.empty?
      soccer_rss.first(25).each do |item|
        category = item.category.content.upcase
        title = item.title
        date = TZInfo::Timezone.get('Europe/Moscow').to_local(item.pubDate).strftime('%d/%m/%Y - %H:%M %Z')
        mobile_link = item.link.gsub('https://www.liveresult.ru/football/matches', 'https://m.liveresult.ru/football/match')
        link = "[Ссылка на текстовую трансляцию](#{mobile_link})"
        soccerlive << [category, title, date, link]
      end
      soccerlive.map { |a, s, d, f| ["*#{a}*", "`#{s}`", "`#{d}`", ["#{f}\n"]] }.join("\n")
    else
      'Spartak! https://youtu.be/ww4pgZWOkqY'
    end
  rescue StandardError
    'There are no `live` list for today now, we will update it soon! / At this time you can check https://m.liveresult.ru/'
  end

  def exclude_ligas
    [
      'Бразилия', 'Австралия', 'Типпелиген', 'Сегунда', 'Вейккауслига', 'Азия', 'Суперэттан',
      'Норвегия / Первый дивизион', 'Беларусь / Премьер-лига', 'США / МЛС', 'ЛИГА ЧЕМПИОНОВ АФК',
      'АЛЛСВЕНСКАН', 'РУМЫНИЯ / ПЕРВАЯ ЛИГА', 'КИТАЙ / СУПЕРЛИГА', 'АРГЕНТИНА / ЛИГА ПРОФЕСЬОНАЛЬ',
      'КОПА СУДАМЕРИКАНА', 'ФНЛ - ПЕРВЫЙ ДИВИЗИОН', 'УКРАИНА / ПРЕМЬЕР-ЛИГА', 'БЕЛЬГИЯ / ПЕРВЫЙ ДИВИЗИОН А',
      'ШВЕЙЦАРИЯ / СУПЕРЛИГА', 'СЛОВАКИЯ / СУПЕРЛИГА', 'СУПЕРЛИГА ДАНИИ', 'ЭКСТРАКЛАССА', 'АВСТРИЯ / БУНДЕСЛИГА',
      'БУНДЕСЛИГА 2', 'ЗОЛОТОЙ КУБОК КОНКАКАФ'
    ].join('|')
  end
end
