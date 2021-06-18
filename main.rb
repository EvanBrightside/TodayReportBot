require 'telegram/bot'
require 'pry'
require 'forecast_io'
require 'rss'
require 'nokogiri'
require 'httparty'
require 'open-uri'
require 'dotenv/load'
require 'tzinfo'

@user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/536.5 (KHTML, like Gecko) Chrome/19.0.1084.56 Safari/536.5'

def weather
  ForecastIO.api_key = '3865f8bb801a9ea17907c763534526c0'
  forecast = ForecastIO.forecast(59.92190399, 30.45242786, params: { lang: 'ru', exclude: 'alerts', units: 'auto' })
  all_day = forecast[:daily][:data].first
  currently = forecast[:currently]

  summary = all_day[:summary]
  icon = all_day[:icon]
  temperature_now = currently[:temperature].round
  temperature_min = all_day[:temperatureMin].round
  temperature_max = all_day[:temperatureMax].round
  sunrise = Time.at(all_day[:sunriseTime]).strftime('%H:%M')
  sunset = Time.at(all_day[:sunsetTime]).strftime('%H:%M')
  wind = all_day[:windSpeed].round(1)

  t0 = temperature_now.positive? ? "+#{temperature_now}" : temperature_now.to_s
  t1 = temperature_min.positive? ? "+#{temperature_min}" : temperature_min.to_s
  t2 = temperature_max.positive? ? "+#{temperature_max}" : temperature_max.to_s

  ic = case icon
       when 'rain', 'light rain'
         '☔'
       when 'cloudy'
         '☁️'
       when 'partly-cloudy-day', 'partly-cloudy-night'
         '⛅'
       when 'clear-day', 'clear-night'
         '☀️'
       when 'snow'
         '❄️'
       when 'sleet'
         '☔❄️'
       else
         icon
       end

  [
    "*Сегодня в Санкт-Петербурге: #{ic}*",
    "*Сейчас: #{t0}°C*",
    "Восход: #{sunrise}",
    "Закат #{sunset}",
    "Ветер: #{wind}м/с",
    "В течение дня: #{t1}°C .. #{t2}°C",
    summary.to_s
  ].join("\n")
end

def dailynews
  items = Nokogiri::XML(open('https://meduza.io/rss/all', { ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE }))
  dailynews = []
  items.css('item')[0..5].map do |item|
    title = "*#{item.at_css('title').text.upcase}*"
    link = "[Полная статья](#{item.at_css('link').text})"
    dailynews << [title, link]
  end
  dailynews.map { |title, link| [[title, "#{link}\n"]] } * "\n"
end

def live
  url = 'https://www.liveresult.ru/football/matches/rss'
  if HTTParty.get(url).code == 200
    rss = RSS::Parser.parse(url)
    soccer_rss = rss.items.select do |a|
      a.category.content !~ /#{exclude_ligas}/ && a.pubDate.strftime('%d/%m/%Y') == Date.today.strftime('%d/%m/%Y')
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
  # %w[Бразилия Австралия Типпелиген Сегунда Вейккауслига Азия Суперэттан].join('|')
  [
    'Бразилия', 'Австралия', 'Типпелиген', 'Сегунда', 'Вейккауслига', 'Азия', 'Суперэттан',
    'Норвегия / Первый дивизион', 'Беларусь / Премьер-лига'
  ].join('|')
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
  transfers.map { |a, s, d| [a, s, ["#{d}\n"]] }.join("\n ")
rescue StandardError
  'There are no `transfers` list for today now, we will update it soon! / You can check http://www.sport-express.ru/football/transfers at this time.'
end

def allsport
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

def currency
  doc = Nokogiri::XML(
    open('http://www.cbr.ru/scripts/XML_daily.asp?', { ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE })
  )
  us = doc.at_css('Valute[ID="R01235"]')
  us_charcode = us.at_css('CharCode').text
  us_value = us.at_css('Value').text
  eu = doc.at_css('Valute[ID="R01239"]')
  eu_charcode = eu.at_css('CharCode').text
  eu_value = eu.at_css('Value').text

  [
    '*Курсы валют на сегодня:*',
    "🇺🇸 1 #{us_charcode} = #{us_value[0..4]} RUB",
    "🇪🇺 1 #{eu_charcode} = #{eu_value[0..4]} RUB"
  ].join("\n")
end

def rubyweekly
  response = Nokogiri::HTML(open('http://rubyweekly.com/', 'User-Agent' => @user_agent))
  doc = response.css('.main p a').attr('href').text
  link = "http://rubyweekly.com#{doc}"
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
rescue StandardError
  'Something wrong / You can check it on https://rubyweekly.com'
end

Telegram::Bot::Client.run(ENV['TG_TOKEN']) do |bot|
  bot.listen do |message|
    markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [%w[📰News 🏟Sport], %w[⛅Weather 🏦Currency]], resize_keyboard: true)
    sport_kb = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [%w[📺AllSport ⚽Live], %w[🔀Transfers ⬅️Back]], resize_keyboard: true)
    news_kb = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [%w[🎙DailyNews 💎RubyWeekly], %w[⬅️Back]], resize_keyboard: true)

    case message.text
    when '/start'
      bot.api.send_message(chat_id: message.chat.id, text: "Hey, #{message&.from&.first_name}!", reply_markup: markup)
    when '📰News'
      bot.api.send_message(chat_id: message.chat.id, text: 'Top News!', reply_markup: news_kb)
    when '💎RubyWeekly'
      bot.api.send_message(chat_id: message.chat.id, text: rubyweekly, parse_mode: 'Markdown', disable_web_page_preview: true)
    when '🎙DailyNews'
      bot.api.send_message(chat_id: message.chat.id, text: dailynews, parse_mode: 'Markdown', disable_web_page_preview: true)
    when '🏟Sport'
      bot.api.send_message(chat_id: message.chat.id, text: 'Sport News!', reply_markup: sport_kb)
    when '⚽Live'
      bot.api.send_message(chat_id: message.chat.id, text: live, parse_mode: 'Markdown', disable_web_page_preview: true)
    when '🔀Transfers'
      bot.api.send_message(chat_id: message.chat.id, text: transfers, parse_mode: 'Markdown', disable_web_page_preview: true)
    when '📺AllSport'
      bot.api.send_message(chat_id: message.chat.id, text: allsport, parse_mode: 'Markdown', disable_web_page_preview: true)
    when '⬅️Back'
      bot.api.send_message(chat_id: message.chat.id, text: 'Back', reply_markup: markup)
    when '⛅Weather'
      bot.api.send_message(chat_id: message.chat.id, text: weather, parse_mode: 'Markdown')
    when '🏦Currency'
      bot.api.send_message(chat_id: message.chat.id, text: currency, parse_mode: 'Markdown')
    end
  end
end
