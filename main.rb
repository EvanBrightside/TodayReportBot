require_relative 'libs'

@user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/536.5 (KHTML, like Gecko) Chrome/19.0.1084.56 Safari/536.5'

Telegram::Bot::Client.run(ENV['TG_TOKEN']) do |bot|
  bot.listen do |message|
    if message.is_a? Telegram::Bot::Types::Message
      ProcessMessage.call(message, bot)
    else
      bot.logger.info('Not sure what to do with this type of message')
    end
  end
end
