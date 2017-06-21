require 'telegram/bot'
require 'nokogiri'
require 'open-uri'
require 'pry'
require 'forecast_io'

TOKEN = '417609760:AAGPXHAH9gqmawMbqRWuE-UiCvmPjTnIAKo'

ForecastIO.api_key = '3865f8bb801a9ea17907c763534526c0'

forecast = ForecastIO.forecast(59.92190399, 30.45242786, params: { lang: 'ru', exclude: 'alerts', units: 'auto' })

weather = forecast.values[6].values[2][0]

date = Time.at(weather.values[0]).strftime("%d %B %a")
summary = weather.values[1]
icon = weather.values[2]
temperature_min = weather.values[11].round
temperature_max = weather.values[13].round
sunrise = Time.at(weather.values[3]).strftime("%H:%M")
sunset = Time.at(weather.values[4]).strftime("%H:%M")
wind = weather.values[9].round(1)

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
	"Сегодня: #{date}",
	"Температура: #{t1}°C .. #{t2}°C",
	"Восход: #{sunrise}",
	"Закат #{sunset}",
	"Ветер: #{wind}м/с",
	"#{summary} #{ic}"
	]*"\n"

doc = Nokogiri::HTML(open("https://www.liveresult.ru/"))

soccer = doc.css('#s_172_actual_pane .mixedtxt-item:not(.date)')
soccerlive = []
soccer.each do |el|
	time = el.css('.mixedtxt-item-info .date')[0].text
	info = el.css('.mixedtxt-item-text a')[0].text
	soccerlive << [time, info]
end

Telegram::Bot::Client.run(TOKEN) do |bot|
	bot.listen do |message|
		kb = [
		 	Telegram::Bot::Types::KeyboardButton.new(text: 'soccer'),
		 	Telegram::Bot::Types::KeyboardButton.new(text: 'weather'),
		 	Telegram::Bot::Types::KeyboardButton.new(text: 'location', request_location: true)
	  	]
 	  markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: kb)

		case message.text
		when "/start"
			bot.api.send_message(chat_id: message.chat.id, text: "Hey!, #{message.from.first_name}", reply_markup: markup)
		when "soccer"
			bot.api.send_message(chat_id: message.chat.id, text: "#{soccerlive}")
		when "weather"
		 	bot.api.send_message(
		 		chat_id: message.chat.id,
		 		text: base_text
		 	)
	  end
	end
end
