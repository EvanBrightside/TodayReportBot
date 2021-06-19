module ProcessMessage
  module_function

  def call(message, bot)
    case message.text
    when '/start'
      bot.api.send_message(chat_id: message.chat.id, text: "Hey, #{message&.from&.first_name}!", reply_markup: markup_kb)
    when '📰News'
      bot.api.send_message(chat_id: message.chat.id, text: 'Top News!', reply_markup: news_kb)
    when '🏟Sport'
      bot.api.send_message(chat_id: message.chat.id, text: 'Sport News!', reply_markup: sport_kb)
    when '⬅️Back'
      bot.api.send_message(chat_id: message.chat.id, text: 'Back', reply_markup: markup_kb)
    when '💎RubyWeekly'
      bot.api.send_message(chat_id: message.chat.id, text: Rubyweekly.call, parse_mode: 'Markdown', disable_web_page_preview: true)
    when '🎙DailyNews'
      bot.api.send_message(chat_id: message.chat.id, text: Dailynews.call, parse_mode: 'Markdown', disable_web_page_preview: true)
    when '⚽Live'
      bot.api.send_message(chat_id: message.chat.id, text: Live.call, parse_mode: 'Markdown', disable_web_page_preview: true)
    when '🔀Transfers'
      bot.api.send_message(chat_id: message.chat.id, text: Transfers.call, parse_mode: 'Markdown', disable_web_page_preview: true)
    when '📺AllSport'
      bot.api.send_message(chat_id: message.chat.id, text: Allsport.call, parse_mode: 'Markdown', disable_web_page_preview: true)
    when '⛅Weather'
      bot.api.send_message(chat_id: message.chat.id, text: Weather.call, parse_mode: 'Markdown')
    when '🏦Currency'
      bot.api.send_message(chat_id: message.chat.id, text: Currency.call, parse_mode: 'Markdown')
    end
  end

  def markup_kb
    tg_keyboard([%w[📰News 🏟Sport], %w[⛅Weather 🏦Currency]])
  end

  def sport_kb
    tg_keyboard([%w[📺AllSport ⚽Live], %w[🔀Transfers ⬅️Back]])
  end

  def news_kb
    tg_keyboard([%w[🎙DailyNews 💎RubyWeekly], %w[⬅️Back]])
  end

  def tg_keyboard(keyboard_buttons)
    Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: keyboard_buttons, resize_keyboard: true)
  end
end
