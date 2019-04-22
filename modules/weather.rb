require 'pry'
require 'forecast_io'
require 'rss'
require 'nokogiri'
require 'httparty'
require 'open-uri'

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
