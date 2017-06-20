require 'telegram/bot'
require 'nokogiri'
require 'open-uri'
require 'pry'
require 'forecast_io'

TOKEN = '417609760:AAGPXHAH9gqmawMbqRWuE-UiCvmPjTnIAKo'

ForecastIO.api_key = '3865f8bb801a9ea17907c763534526c0'

forecast = ForecastIO.forecast(59.92190399, 30.45242786, params: { lang: 'ru', exclude: 'currently', units: 'auto' })
weather = forecast.values[4].values[2][0]
date = Time.at(weather.values[0]).strftime("%d-%m-%y")
time = Time.at(weather.values[0]).strftime("%H:%M"),
summary = weather.values[1],
icon = weather.values[2],
temperature = weather.values[5],
wind = weather.values[9]

doc = Nokogiri::HTML(open("http://www.liveresult.ru/"))

soccer = doc.css('#s_172_actual_pane .mixedtxt-item:not(.date)')
soccerlive = []
soccer.each do |el|
	time = el.css('.mixedtxt-item-info .date')[0].text
	info = el.css('.mixedtxt-item-text a')[0].text
	soccerlive = [time, info]*" - "
end

Telegram::Bot::Client.run(TOKEN) do |bot|
	bot.listen do |message|
		kb = [
		 	Telegram::Bot::Types::KeyboardButton.new(text: 'live'),
		 	Telegram::Bot::Types::KeyboardButton.new(text: 'weather'),
		 	Telegram::Bot::Types::KeyboardButton.new(text: 'location', request_location: true)
	  	]
 	  markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: kb)

		case message.text
		when "/start"
			bot.api.send_message(chat_id: message.chat.id, text: "Hey!, #{message.from.first_name}", reply_markup: markup)
		when "live"
			bot.api.send_message(chat_id: message.chat.id, text: "#{soccerlive}")
		when "weather"
		 	bot.api.send_message(
		 		chat_id: message.chat.id,
		 		text: "Дата: #{date} / Время: #{time} / Температура: #{temperature}C / Ветер: #{wind}м/с / #{summary} / #{icon}"
		 	)
	  end
	end
end
