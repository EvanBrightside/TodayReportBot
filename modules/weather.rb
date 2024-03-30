module Weather
  module_function

  def call(city = nil)
    headers = {
      'X-RapidAPI-Key': ENV['WEATHER_API_KEY'],
      'X-RapidAPI-Host': 'weatherapi-com.p.rapidapi.com'
    }
    current_city = city.nil? ? 'saint-petersburg' : city
    url = "https://weatherapi-com.p.rapidapi.com/forecast.json?q=#{current_city}"
    response = HTTParty.get(url, headers: headers)
    return 'Weather unavailable' if response.code != 200

    forecast = response.dig('forecast', 'forecastday')&.first
    return 'Weather unavailable' if (forecast.nil? || forecast.empty?)

    currently = response['current']
    forecast_day = forecast['day']
    forecast_astro = forecast['astro']

    icon_code = currently.dig('condition', 'code')
    temperature_now = currently['temp_c']&.round
    temperature_min = forecast_day['mintemp_c']&.round
    temperature_max = forecast_day['maxtemp_c']&.round
    sunrise = forecast_astro['sunrise']
    sunset = forecast_astro['sunset']
    wind = (currently['wind_kph'] / 3.6).round(1)

    t0 = temperature_now.positive? ? "+#{temperature_now}" : temperature_now.to_s
    t1 = temperature_min.positive? ? "+#{temperature_min}" : temperature_min.to_s
    t2 = temperature_max.positive? ? "+#{temperature_max}" : temperature_max.to_s

    ic = case icon_code
          when 1063, 1180, 1183, 1186, 1189, 1192, 1195, 1198, 1201, 1240, 1243, 1246, 1273, 1276
            '☔'
          when 1003, 1006
            '☁️'
          when 1009, 1030
            '⛅'
          when 1000
           '☀️'
          when 1066, 1114, 1210, 1213, 1216, 1219, 1222, 1225, 1255, 1258, 1279, 1282
            '❄️'
          when 1069, 1204, 1207, 1249, 1252
            '☔❄️'
          else
            currently.dig('condition', 'text')
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
      "Ветер: #{wind} м/с",
      "В течение дня: #{t1}°C .. #{t2}°C"
    ].join("\n")
  end
end
