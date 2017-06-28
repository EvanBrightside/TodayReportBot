require 'telegram/bot'
require 'pry'
require 'forecast_io'
require 'rss'
require 'nokogiri'
require 'httparty'
require 'open-uri'

TOKEN = "417609760:AAGPXHAH9gqmawMbqRWuE-UiCvmPjTnIAKo"

@user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/536.5 (KHTML, like Gecko) Chrome/19.0.1084.56 Safari/536.5'

def weather
	ForecastIO.api_key = '3865f8bb801a9ea17907c763534526c0'

	forecast = ForecastIO.forecast(59.92190399, 30.45242786, params: { lang: 'ru', exclude: 'alerts', units: 'auto' })

	all_day = forecast[:daily][:data].first
	currently = forecast[:currently]

	date = Time.at(all_day[:time]).strftime("%d %B %a")
	summary = all_day[:summary]
	icon = all_day[:icon]
	temperature_now = currently[:temperature].round
	temperature_min = all_day[:temperatureMin].round
	temperature_max = all_day[:temperatureMax].round
	sunrise = Time.at(all_day[:sunriseTime]).strftime("%H:%M")
	sunset = Time.at(all_day[:sunsetTime]).strftime("%H:%M")
	wind = all_day[:windSpeed].round(1)

	t0 = "+#{temperature_now}" if temperature_now > 0
	t1 = "+#{temperature_min}" if temperature_min > 0
	t2 = "+#{temperature_max}" if temperature_max > 0

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

def soccer
	soccer_rss = RSS::Parser.parse('https://www.liveresult.ru/football/txt/rss')
	soccerlive = []
	soccer_rss.items.each do |item|
		category = "*#{item.category.content.upcase}*"
	 	title = item.title
	 	date = item.pubDate.strftime("%d/%m/%Y - %H:%M")
	  link = "[Ссылка на текстовую трансляцию](#{item.link})"
	  soccerlive << [category, title, date, link]
	end
	s = soccerlive.map { |a, s, d, f| [ a, s, d, ["#{f}\n"] ] }*"\n"
end

def currency
	doc = Nokogiri::XML(open("http://www.cbr.ru/scripts/XML_daily.asp?"))
	us = doc.at_css('Valute[ID="R01235"]')
	us_charcode = us.at_css('CharCode').text
	us_value = us.at_css('Value').text
	eu = doc.at_css('Valute[ID="R01239"]')
	eu_charcode = eu.at_css('CharCode').text
	eu_value = eu.at_css('Value').text

	currency_ex = [
		"*Курсы валют на сегодня:*",
		"🇺🇸 1 #{us_charcode} = #{us_value} RUB",
		"🇪🇺 1 #{eu_charcode} = #{eu_value} RUB"
	]*"\n"
end

def rubyweekly
	url = 'http://rubyweekly.com'
	response = Nokogiri::HTML(open('http://rubyweekly.com/', 'User-Agent' => @user_agent))
	doc = response.css('.sample a').attr('href').text
	link = url+doc
	feed = Nokogiri::HTML(open(link))
	issues = feed.css('.issue-html .gowide').select { |a| a[:width] == '100%' }
	ruby_issues = []
	issues.map { |s|
		title = s.at_css('div[2]').text.upcase
		main_text = s.at_css('div[3]').text
		link = s.at_css('a')[:href]
		ruby_issues << [title, main_text, link]
	}
	ruby_issues.map { |a, s, d| [ a, s, ["#{d}\n"]] }*"\n"
end

Telegram::Bot::Client.run(TOKEN) do |bot|
	bot.listen do |message|
 	  markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [%w(⚽Soccer ⛅Weather), %w(📰RubyWeekly 🏦Currency)], resize_keyboard: true)

		case message.text
		when "/start"
			bot.api.send_message(chat_id: message.chat.id, text: "Hey, #{message.from.first_name}!", reply_markup: markup)
		when "⚽Soccer"
			bot.api.send_message(chat_id: message.chat.id, text: soccer, parse_mode: 'Markdown', disable_web_page_preview: true)
		when "⛅Weather"
		 	bot.api.send_message(chat_id: message.chat.id, text: weather, parse_mode: 'Markdown')
		when "📰RubyWeekly"
		 	bot.api.send_message(chat_id: message.chat.id, text: rubyweekly, disable_web_page_preview: true)
		when "🏦Currency"
		 	bot.api.send_message(chat_id: message.chat.id, text: currency, parse_mode: 'Markdown')
	  end
	end
end
