require 'telegram/bot'
require 'pry'
require 'forecast_io'
require 'rss'
require 'nokogiri'
require 'httparty'
require 'open-uri'
require 'mongo'
require 'launchy'
require 'redis'
require 'rufus-scheduler'

@scheduler = Rufus::Scheduler.new

TOKEN = '417609760:AAGPXHAH9gqmawMbqRWuE-UiCvmPjTnIAKo'

@user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/536.5 (KHTML, like Gecko) Chrome/19.0.1084.56 Safari/536.5'

redis_uri = ENV['REDISTOGO_URL'] || 'redis://localhost:6379'
uri = URI.parse(redis_uri)
REDIS = Redis.new(host: uri.host, port: uri.port, password: uri.password)

def weather
  ForecastIO.api_key = '3865f8bb801a9ea17907c763534526c0'
  forecast = ForecastIO.forecast(59.92190399, 30.45242786, params: { lang: 'ru', exclude: 'alerts', units: 'auto' })
  all_day = forecast[:daily][:data].first
  currently = forecast[:currently]

  date = Time.at(all_day[:time]).strftime('%d %B %a')
  summary = all_day[:summary]
  icon = all_day[:icon]
  temperature_now = currently[:temperature].round
  temperature_min = all_day[:temperatureMin].round
  temperature_max = all_day[:temperatureMax].round
  sunrise = Time.at(all_day[:sunriseTime]).strftime('%H:%M')
  sunset = Time.at(all_day[:sunsetTime]).strftime('%H:%M')
  wind = all_day[:windSpeed].round(1)

  t0 = temperature_now > 0 ? "+#{temperature_now}" : temperature_now.to_s
  t1 = temperature_min > 0 ? "+#{temperature_min}" : temperature_min.to_s
  t2 = temperature_max > 0 ? "+#{temperature_max}" : temperature_max.to_s

  if icon == "rain" || icon == "light rain"
    ic = "☔"
  elsif icon == "cloudy"
    ic = "☁️"
  elsif icon == "partly-cloudy-day" || icon == "partly-cloudy-night"
    ic = "⛅"
  elsif icon == "clear-day" || icon == "clear-night"
    ic = "☀️"
  elsif icon == "snow"
    ic = "❄️"
  elsif icon == "sleet"
    ic = "☔❄️"
  else
    icon
  end

  base_text = [
    "*Сегодня: #{date} #{ic}*",
    "*Сейчас: #{t0}°C*",
    "Восход: #{sunrise}",
    "Закат #{sunset}",
    "Ветер: #{wind}м/с",
    "В течение дня: #{t1}°C .. #{t2}°C",
    "#{summary}"
  ]*"\n"
end

def dailynews
  items = Nokogiri::XML(open('https://meduza.io/rss/all', {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}))
  dailynews = []
  items.css('item')[0..5].map do |item|
    title = "*#{item.at_css('title').text.upcase}*"
    description = "`#{item.at_css('description').text}`"
    link = "[Полная статья](#{item.at_css('link').text})"
    dailynews << [title, description, link]
  end
  dailynews.map { |a, s, d| [ a, s, ["#{d}\n"] ] }*"\n"
end

def devby
  items = Nokogiri::XML(open('https://dev.by/rss', {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}))
  devby = []
  items.css('entry')[0..5].map do |item|
    title = "*#{item.at_css('title').text.upcase}*"
    description = "`#{item.at_css('summary').children[0].text.gsub(/\<(.*?)\>|&mdash;|&#8203;/i,"").gsub(/&nbsp;|&laquo;|&raquo;/i," ").split("\n")[0]}`"
    link = "[Полная статья](#{item.at_css('link').attributes['href'].value})"
    devby << [title, description, link]
  end
  devby.map { |a, s, d| [ a, s, ["#{d}\n"] ] }*"\n"
end

def live
  url = 'https://www.liveresult.ru/football/matches/rss'
  begin
    if HTTParty.get(url).code == 200
      rss = RSS::Parser.parse(url)
      liga = %w[ Лига Международный Товарищеские Европы Мира ].join('|')
      # binding.pry
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
    "There are no `live` list for today now, we will update it soon! / At this time you can check #{'https://m.liveresult.ru/'}"
  end
end

def live_ru
  url = 'https://www.liveresult.ru/football/matches/rss'
  begin
    if HTTParty.get(url).code == 200
      rss = RSS::Parser.parse(url)
      liga = 'Россия'
      # binding.pry
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
    "There are no `live` list for today now, we will update it soon! / At this time you can check #{'https://m.liveresult.ru/'}"
  end
end

def live_ru
  url = 'https://www.liveresult.ru/football/matches/rss'
  begin
    if HTTParty.get(url).code == 200
      rss = RSS::Parser.parse(url)
      liga = 'Россия'
      # binding.pry
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
    "There are no `live` list for today now, we will update it soon! / At this time you can check #{'https://m.liveresult.ru/'}"
  end
end


def live_ru
  url = 'https://www.liveresult.ru/football/matches/rss'
  begin
    if HTTParty.get(url).code == 200
      rss = RSS::Parser.parse(url)
      liga = 'Россия'
      # binding.pry
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
    "There are no `live` list for today now, we will update it soon! / At this time you can check #{'https://m.liveresult.ru/'}"
  end
end

def live_it
  url = 'https://www.liveresult.ru/football/matches/rss'
  begin
    if HTTParty.get(url).code == 200
      rss = RSS::Parser.parse(url)
      liga = 'Италия'
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
    "There are no `live` list for today now, we will update it soon! / At this time you can check #{'https://m.liveresult.ru/'}"
  end
end

def live_en
  url = 'https://www.liveresult.ru/football/matches/rss'
  begin
    if HTTParty.get(url).code == 200
      rss = RSS::Parser.parse(url)
      liga = 'Англия'
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
    "There are no `live` list for today now, we will update it soon! / At this time you can check #{'https://m.liveresult.ru/'}"
  end
end

def live_de
  url = 'https://www.liveresult.ru/football/matches/rss'
  begin
    if HTTParty.get(url).code == 200
      rss = RSS::Parser.parse(url)
      liga = 'Германия'
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
    "There are no `live` list for today now, we will update it soon! / At this time you can check #{'https://m.liveresult.ru/'}"
  end
end

def live_es
  url = 'https://www.liveresult.ru/football/matches/rss'
  begin
    if HTTParty.get(url).code == 200
      rss = RSS::Parser.parse(url)
      liga = 'Испания'
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
    "There are no `live` list for today now, we will update it soon! / At this time you can check #{'https://m.liveresult.ru/'}"
  end
end

def live_fr
  url = 'https://www.liveresult.ru/football/matches/rss'
  begin
    if HTTParty.get(url).code == 200
      rss = RSS::Parser.parse(url)
      liga = 'Франция'
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
    "There are no `live` list for today now, we will update it soon! / At this time you can check #{'https://m.liveresult.ru/'}"
  end
end

def live_nl
  url = 'https://www.liveresult.ru/football/matches/rss'
  begin
    if HTTParty.get(url).code == 200
      rss = RSS::Parser.parse(url)
      liga = 'Голландия'
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
    "There are no `live` list for today now, we will update it soon! / At this time you can check #{'https://m.liveresult.ru/'}"
  end
end

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

def allsport
  begin
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
      sport = allsport.map { |a, s, d, f| [ a, s, d, ["#{f}\n "] ] }*"\n"
      sport
    else
      sp_url = 'https://youtu.be/ww4pgZWOkqY'
      "Spartak! #{sp_url}"
    end
  rescue
    'Not avaliable now / telegram stuff, nothing to worry!'
  end
end

def currency
  doc = Nokogiri::XML(open("http://www.cbr.ru/scripts/XML_daily.asp?", {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}))
  us = doc.at_css('Valute[ID="R01235"]')
  us_charcode = us.at_css('CharCode').text
  us_value = us.at_css('Value').text
  eu = doc.at_css('Valute[ID="R01239"]')
  eu_charcode = eu.at_css('CharCode').text
  eu_value = eu.at_css('Value').text

  bitcoin_url = 'https://api.coinmarketcap.com/v1/ticker/bitcoin/'
  bitcoin_response = HTTParty.get(bitcoin_url)
  bitcoin_h = bitcoin_response.parsed_response.first
  usd_bt = bitcoin_h["price_usd"]

  ethereum_url = 'https://api.coinmarketcap.com/v1/ticker/ethereum/'
  ethereum_response = HTTParty.get(ethereum_url)
  ethereum_h = ethereum_response.parsed_response.first
  usd_et = ethereum_h["price_usd"]

  ripple_url = 'https://api.coinmarketcap.com/v1/ticker/ripple/'
  ripple_response = HTTParty.get(ripple_url)
  ripple_h = ripple_response.parsed_response.first
  usd_rp = ripple_h["price_usd"]

  [
    '*Курсы валют на сегодня:*',
    "🇺🇸 1 #{us_charcode} = #{us_value} RUB",
    "🇪🇺 1 #{eu_charcode} = #{eu_value} RUB",
    "🔶 1 BTC = #{usd_bt} USD",
    "🔷 1 ETH = #{usd_et} USD",
    "◼️ 1 XRP = #{usd_rp} USD"
  ]*"\n"
end

def rubyweekly
  begin
    response = Nokogiri::HTML(open('http://rubyweekly.com/', 'User-Agent' => @user_agent))
    doc = response.css('.main p a').attr('href').text
    link = 'http://rubyweekly.com' + doc
    feed = Nokogiri::XML(open(link, {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}))
    issues = feed.css('.el-item .item')
    rubyissues = []
    issues.map do |s|
      title = "*#{s.at_css('a').text.upcase}*"
      main_text = "`#{s.at_css('p').children.map(&:text)[1]}`"
      link = "[link](#{s.at_css('a')[:href]})"
      rubyissues << [title, main_text, link]
    end
    rubyissues.map { |a, s, d| [ a, s, ["#{d}\n"] ] }*"\n"
  rescue => e
    "Something wrong / You can check it on #{'https://rubyweekly.com/'}"
  end
end

Telegram::Bot::Client.run(TOKEN) do |bot|
  bot.listen do |message|

    markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [%w(📰News 🏟Sport), %w(⛅Weather 🏦Currency)], resize_keyboard: true)

    sport_kb = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [%w(📺AllSport ⚽Live), %w(🔀Transfers ⬅️Back)], resize_keyboard: true)

    news_kb = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [%w(🎙DailyNews 👨🏽‍💻DevBY), %w(💎RubyWeekly ⬅️Back)], resize_keyboard: true)

    liveresult_kb = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [%w(🌏Countries 🏟Other), %w(⬅️Back)], resize_keyboard: true)

    live_countries_kb = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [%w(🇷🇺Russia 🇮🇹Italy), %w(🏴󠁧󠁢󠁥󠁮󠁧󠁿England 🇩🇪Germany), %w(🇪🇸Spain 🇫🇷France), %w(🇳🇱Голландия ⬅️Back)], resize_keyboard: true)

    case message.text
    when '/start'
      REDIS.set message.chat.id.to_s, message.chat.first_name.to_s
      bot.api.send_message(chat_id: message.chat.id, text: "Hey, #{message.from.first_name}!", reply_markup: markup)

      text = '🤖 Так, срочно заплати за интернет 👨🏽‍💻 свет 💡 и квартиру 🏠'

      @scheduler.cron '00 09 30 * *' do
        bot.api.send_message(chat_id: 114436135, text: text)
      end
    when '📰News'
      REDIS.set message.chat.id.to_s, message.chat.first_name.to_s
      bot.api.send_message(chat_id: message.chat.id, text: "Top News!", reply_markup: news_kb)
    when "💎RubyWeekly"
      bot.api.send_message(chat_id: message.chat.id, text: rubyweekly, parse_mode: 'Markdown', disable_web_page_preview: true)
    when "👨🏽‍💻DevBY"
      bot.api.send_message(chat_id: message.chat.id, text: devby, parse_mode: 'Markdown', disable_web_page_preview: true)
    when "🎙DailyNews"
      bot.api.send_message(chat_id: message.chat.id, text: dailynews, parse_mode: 'Markdown', disable_web_page_preview: true)
    when "🏟Sport"
      bot.api.send_message(chat_id: message.chat.id, text: "Sport News!", reply_markup: sport_kb)
    when "⚽Live"
      bot.api.send_message(chat_id: message.chat.id, text: "Championships by countries or other competitions?", reply_markup: liveresult_kb)
    when "🌏Countries"
      bot.api.send_message(chat_id: message.chat.id, text: "Choose a country please", reply_markup: live_countries_kb)
    when "🇷🇺Russia"
      bot.api.send_message(chat_id: message.chat.id, text: live_ru, parse_mode: 'Markdown', disable_web_page_preview: true)
    when "🇮🇹Italy"
      bot.api.send_message(chat_id: message.chat.id, text: live_it, parse_mode: 'Markdown', disable_web_page_preview: true)
    when "🏴󠁧󠁢󠁥󠁮󠁧󠁿England"
      bot.api.send_message(chat_id: message.chat.id, text: live_en, parse_mode: 'Markdown', disable_web_page_preview: true)
    when "🇩🇪Germany"
      bot.api.send_message(chat_id: message.chat.id, text: live_de, parse_mode: 'Markdown', disable_web_page_preview: true)
    when "🇪🇸Spain"
      bot.api.send_message(chat_id: message.chat.id, text: live_es, parse_mode: 'Markdown', disable_web_page_preview: true)
    when "🇫🇷France"
      bot.api.send_message(chat_id: message.chat.id, text: live_fr, parse_mode: 'Markdown', disable_web_page_preview: true)
    when "🇳🇱Голландия"
      bot.api.send_message(chat_id: message.chat.id, text: live_nl, parse_mode: 'Markdown', disable_web_page_preview: true)
    when "🏟Other"
      bot.api.send_message(chat_id: message.chat.id, text: live, parse_mode: 'Markdown', disable_web_page_preview: true)
    when "🔀Transfers"
      bot.api.send_message(chat_id: message.chat.id, text: transfers, parse_mode: 'Markdown', disable_web_page_preview: true)
    when "📺AllSport"
      bot.api.send_message(chat_id: message.chat.id, text: allsport, parse_mode: 'Markdown', disable_web_page_preview: true)
    when "⬅️Back"
      bot.api.send_message(chat_id: message.chat.id, text: "Back", reply_markup: markup)
    when "⛅Weather"
      REDIS.set message.chat.id.to_s, message.chat.first_name.to_s
      bot.api.send_message(chat_id: message.chat.id, text: weather, parse_mode: 'Markdown')
    when "🏦Currency"
      REDIS.set message.chat.id.to_s, message.chat.first_name.to_s
      bot.api.send_message(chat_id: message.chat.id, text: currency, parse_mode: 'Markdown')
    end
  end
  @scheduler.join
end
