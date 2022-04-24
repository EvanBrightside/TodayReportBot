module ProcessMessage
  module_function

  def call(message, bot)
    case message.text
    when '/start'
      bot.api.send_message(chat_id: message.chat.id, text: hello_message(message), reply_markup: markup_kb)
    when '📰 News'
      bot.api.send_message(chat_id: message.chat.id, text: 'Top News!', reply_markup: news_kb)
    when '🏟 Sport'
      bot.api.send_message(chat_id: message.chat.id, text: 'Sport News!', reply_markup: sport_kb)
    when '⛅ Weather'
      bot.api.send_message(chat_id: message.chat.id, text: 'Weather!', reply_markup: weather_kb)
    when '⬅️ Back'
      bot.api.send_message(chat_id: message.chat.id, text: 'Back', reply_markup: markup_kb)
    when '💎 Ruby Weekly'
      bot.api.send_message(chat_id: message.chat.id, text: Rubyweekly.call, parse_mode: 'Markdown', disable_web_page_preview: true)
    when '🎙 Daily News'
      bot.api.send_message(chat_id: message.chat.id, text: Dailynews.call, parse_mode: 'Markdown', disable_web_page_preview: true)
    when '⚽ Live'
      bot.api.send_message(chat_id: message.chat.id, text: Live.call, parse_mode: 'Markdown', disable_web_page_preview: true)
    when '🔀 Transfers'
      bot.api.send_message(chat_id: message.chat.id, text: Transfers.call, parse_mode: 'Markdown', disable_web_page_preview: true)
    when '📺 All Sport'
      bot.api.send_message(chat_id: message.chat.id, text: Allsport.call, parse_mode: 'Markdown', disable_web_page_preview: true)
    when '🇷🇺 Saint-P'
      bot.api.send_message(chat_id: message.chat.id, text: Weather.call(:spb), parse_mode: 'Markdown', disable_web_page_preview: true)
    when '🇷🇸 Belgrade'
      bot.api.send_message(chat_id: message.chat.id, text: Weather.call(:belgrade), parse_mode: 'Markdown', disable_web_page_preview: true)
    when '🏦 Currency'
      bot.api.send_message(chat_id: message.chat.id, text: Currency.call, parse_mode: 'Markdown')
    when '🗒 Список дел'
      response = Todo.call
      markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(
        inline_keyboard: [Telegram::Bot::Types::InlineKeyboardButton.new(text: response[:text], url: response[:url])]
      )
      bot.api.send_message(chat_id: message.chat.id, text: 'Посмотреть / создать / обновить ⬇️', reply_markup: markup)
    when '🏋️‍♂️ Fitness'
      response = Fitness.call
      markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(
        inline_keyboard: [Telegram::Bot::Types::InlineKeyboardButton.new(text: response[:text], url: response[:url])]
      )
      bot.api.send_message(chat_id: message.chat.id, text: 'Расписание на неделю в FH ⬇️', reply_markup: markup)
    end
  end

  def hello_message(message)
    return "Hey, #{message&.from&.first_name}!" unless message&.from&.first_name.nil?

    'Hello my friend!'
  end

  def markup_kb
    tg_keyboard([['📰 News', '🏟 Sport'], ['⛅ Weather', '🏦 Currency'], ['🗒 Список дел', '🏋️‍♂️ Fitness']])
  end

  def sport_kb
    tg_keyboard([['📺 All Sport', '⚽ Live'], ['🔀 Transfers', '⬅️ Back']])
  end

  def news_kb
    tg_keyboard([['🎙 Daily News', '💎 Ruby Weekly'], ['⬅️ Back']])
  end

  def weather_kb
    tg_keyboard([['🇷🇺 Saint-P', '🇷🇸 Belgrade'], ['⬅️ Back']])
  end

  def tg_keyboard(keyboard_buttons)
    Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: keyboard_buttons, resize_keyboard: true)
  end
end
