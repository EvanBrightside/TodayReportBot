module Weather
  module_function

  def call(city = nil)
    city_coords = {
      belgrade: { lat: '44.804', lon: '20.4651' },
      spb: { lat: '59.92190399', lon: '30.45242786' }
    }

    ForecastIO.api_key = ENV['WEATHER_API_KEY']
    coords = city.nil? ? { lat: '59.92190399', lon: '30.45242786' } : city_coords[city]
    forecast = ForecastIO.forecast(coords[:lat].to_f, coords[:lon].to_f, params: { lang: 'ru', exclude: 'alerts', units: 'auto' })
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

    city_name = {
      belgrade: 'Белграде',
      spb: 'Санкт-Петербурге'
    }

    today_city = city.nil? ? 'Санкт-Петербурге' : city_name[city]

    [
      "*Сегодня в #{today_city}: #{ic}*",
      "*Сейчас: #{t0}°C*",
      "Восход: #{sunrise}",
      "Закат #{sunset}",
      "Ветер: #{wind}м/с",
      "В течение дня: #{t1}°C .. #{t2}°C",
      summary.to_s
    ].join("\n")
  end
end
