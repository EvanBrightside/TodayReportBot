require 'telegram/bot'
require 'pry'
require 'forecast_io'
require 'rss'
require 'nokogiri'
require 'httparty'
require 'open-uri'

TOKEN = '417609760:AAGPXHAH9gqmawMbqRWuE-UiCvmPjTnIAKo'

ForecastIO.api_key = '3865f8bb801a9ea17907c763534526c0'

forecast = ForecastIO.forecast(59.92190399, 30.45242786, params: { lang: 'ru', exclude: 'alerts', units: 'auto' })

weather = forecast.values[6].values[2][0]

date = Time.at(weather.values[0]).strftime("%d %B %a")
summary = weather.values[1]
icon = weather.values[2]
temperature_now = forecast.values[4].values[5].round
temperature_min = weather.values[11].round
temperature_max = weather.values[13].round
sunrise = Time.at(weather.values[3]).strftime("%H:%M")
sunset = Time.at(weather.values[4]).strftime("%H:%M")
wind = weather.values[9].round(1)

t0 = "+#{temperature_now}" if temperature_now > 0
t1 = "+#{temperature_min}" if temperature_min > 0
t2 = "+#{temperature_max}" if temperature_max > 0

if icon == "rain" || icon == "light rain"
	ic = "☔"
elsif icon == "cloudy"
	ic = "☁️"
elsif icon == "partly-cloudy-day"
	ic = "⛅"
else
	icon
end

base_text = [
	"Сегодня: #{date} #{ic}",
	"Сейчас: #{t0}°C",
	"Восход: #{sunrise}",
	"Закат #{sunset}",
	"Ветер: #{wind}м/с",
	"В течение дня: #{t1}°C .. #{t2}°C",
	"#{summary}"
]*"\n"

def soccer
	soccerlive = []
	soccer_rss = RSS::Parser.parse('https://www.liveresult.ru/football/txt/rss')
	soccer_rss.items.each do |item|
	 	title = item.title
	 	date = item.pubDate.strftime("%d/%m/%Y - %H:%M")
	  link = item.link
	  soccerlive << [title, date, link]
	end
	soccerlive*"\n"
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
		"Курсы валют на сегодня:",
		"🇺🇸 1 #{us_charcode} = #{us_value} RUB",
		"🇪🇺 1 #{eu_charcode} = #{eu_value} RUB"
	]*"\n"
end

Telegram::Bot::Client.run(TOKEN) do |bot|
	bot.listen do |message|
 	  markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [%w(⚽Soccer ⛅Weather), %w(📰RubyWeekly 🏦Currency)], resize_keyboard: true)

		case message.text
		when "/start"
			bot.api.send_message(chat_id: message.chat.id, text: "Hey, #{message.from.first_name}!", reply_markup: markup)
		when "⚽Soccer"
			bot.api.send_message(chat_id: message.chat.id, text: soccer)
		when "⛅Weather"
		 	bot.api.send_message(chat_id: message.chat.id, text: base_text)
		when "📰RubyWeekly"
		 	bot.api.send_message(chat_id: message.chat.id, text: "Скоро тут будут новости про Ruby!")
		when "🏦Currency"
		 	bot.api.send_message(chat_id: message.chat.id, text: currency)
	  end
	end
end
