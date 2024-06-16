module ProcessCallback
  module_function

  def call(message, bot)
    info = case message.data
           when 'saint-petersburg', 'belgrade', 'bilbao', 'gijon'
            weather_for(message.data.to_sym)
           when 'rpl', 'euro24'
            live(message.data.to_sym)
           end
    bot.api.send_message(chat_id: message.from.id, text: info, parse_mode: 'Markdown', disable_web_page_preview: true)
  end

  def weather_for(city)
    Weather.call(city)
  end

  def live(liga_name)
    Live.call(liga_name)
  end
end
