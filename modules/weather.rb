module Weather
  module_function

  def call
    ForecastIO.api_key = ENV['WEATHER_API_KEY']
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
end
