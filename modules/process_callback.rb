module ProcessCallback
  module_function

  def call(message, bot)
    info = case message.data
           when 'spb', 'belgrade'
             weather_for(message.data.to_sym)
           when 'rpl'
             rpl
           end
    bot.api.send_message(chat_id: message.from.id, text: info, parse_mode: 'Markdown', disable_web_page_preview: true)
  end

  def weather_for(city)
    Weather.call(city)
  end

  def rpl
    Live.call(true)
  end
end
