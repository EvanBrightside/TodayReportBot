require 'telegram/bot'
require 'pry'
require 'forecast_io'
require 'rss'
require 'nokogiri'
require 'httparty'
require 'open-uri'
require 'dotenv/load'
require 'tzinfo'
require_relative 'modules/rubyweekly'
require_relative 'modules/dailynews'
require_relative 'modules/live'
require_relative 'modules/transfers'
require_relative 'modules/allsport'
require_relative 'modules/weather'
require_relative 'modules/currency'

@user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/536.5 (KHTML, like Gecko) Chrome/19.0.1084.56 Safari/536.5'

Telegram::Bot::Client.run(ENV['TG_TOKEN']) do |bot|
  bot.listen do |message|
    markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [%w[📰News 🏟Sport], %w[⛅Weather 🏦Currency]], resize_keyboard: true)
    sport_kb = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [%w[📺AllSport ⚽Live], %w[🔀Transfers ⬅️Back]], resize_keyboard: true)
    news_kb = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [%w[🎙DailyNews 💎RubyWeekly], %w[⬅️Back]], resize_keyboard: true)

    case message.text
    when '/start'
      bot.api.send_message(chat_id: message.chat.id, text: "Hey, #{message&.from&.first_name}!", reply_markup: markup)
    when '📰News'
      bot.api.send_message(chat_id: message.chat.id, text: 'Top News!', reply_markup: news_kb)
    when '🏟Sport'
      bot.api.send_message(chat_id: message.chat.id, text: 'Sport News!', reply_markup: sport_kb)
    when '⬅️Back'
      bot.api.send_message(chat_id: message.chat.id, text: 'Back', reply_markup: markup)
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
end
