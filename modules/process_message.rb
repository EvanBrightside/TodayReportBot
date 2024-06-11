module ProcessMessage
  module_function

  def call(message, bot)
    case message.text
    when '/start'
      bot.api.send_message(chat_id: message.chat.id, text: hello_message(message), reply_markup: markup_kb)
    when '⭐️ New Relic'
      web_app = Telegram::Bot::Types::WebAppInfo.new(url: Newrelic.call)
      kb = [[Telegram::Bot::Types::InlineKeyboardButton.new(text: 'OPEN IT', web_app: web_app)]]
      markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
      bot.api.send_message(chat_id: message.chat.id, text: '♻️ NewRelic Dashboard ♻️', reply_markup: markup)
    when '📰 News'
      bot.api.send_message(chat_id: message.chat.id, text: 'Top News!', reply_markup: news_kb)
    when '🏟 Sport'
      bot.api.send_message(chat_id: message.chat.id, text: 'Sport News!', reply_markup: sport_kb)
    when '⛅ Weather'
      kb = [
        [
          Telegram::Bot::Types::InlineKeyboardButton.new(text: '🇷🇺 Saint-P', callback_data: 'saint-petersburg'),
          Telegram::Bot::Types::InlineKeyboardButton.new(text: '🇷🇸 Belgrade', callback_data: 'belgrade')
        ]
      ]
      weather_kb = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
      bot.api.send_message(chat_id: message.chat.id, text: 'Choose a city', reply_markup: weather_kb)
    when '⬅️ Back'
      bot.api.send_message(chat_id: message.chat.id, text: 'Back', reply_markup: markup_kb)
    when '💎 Ruby Weekly'
      web_app = Telegram::Bot::Types::WebAppInfo.new(url: Rubyweekly.call)
      kb = [[Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Open Web App', web_app: web_app)]]
      markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
      bot.api.send_message(chat_id: message.chat.id, text: 'Rubyweekly!', reply_markup: markup)
      # bot.api.send_message(chat_id: message.chat.id, text: Rubyweekly.call, parse_mode: 'Markdown', disable_web_page_preview: true)
    when '🎙 Daily News'
      bot.api.send_message(chat_id: message.chat.id, text: Dailynews.call, parse_mode: 'Markdown', disable_web_page_preview: true)
    when '⚽ Live'
      kb = [[Telegram::Bot::Types::InlineKeyboardButton.new(text: '🐻 Russian Premier League', callback_data: 'rpl')]]
      live_kb = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
      bot.api.send_message(chat_id: message.chat.id, text: Live.call, parse_mode: 'Markdown', disable_web_page_preview: true, reply_markup: live_kb)
    when '🔀 Transfers'
      bot.api.send_message(chat_id: message.chat.id, text: Transfers.call, parse_mode: 'Markdown', disable_web_page_preview: true)
    when '📺 All Sport'
      bot.api.send_message(chat_id: message.chat.id, text: Allsport.call, parse_mode: 'Markdown', disable_web_page_preview: true)
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
    tg_keyboard([[{ text: '📰 News' }, { text: '🏟 Sport' }], [{ text: '⛅ Weather' }, { text: '🏦 Currency' }]]) # , ['🗒 Список дел', '🏋️‍♂️ Fitness']
  end

  def sport_kb
    tg_keyboard([[{ text: '📺 All Sport' }, { text: '⚽ Live' }], [{ text: '🔀 Transfers' }, { text: '⬅️ Back' }]])
  end

  def news_kb
    tg_keyboard([[{ text: '🎙 Daily News' }, { text: '💎 Ruby Weekly' }], [{ text: '⭐️ New Relic' }, { text: '⬅️ Back' }]])
  end

  def tg_keyboard(keyboard_buttons)
    Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: keyboard_buttons, resize_keyboard: true)
  end
end
