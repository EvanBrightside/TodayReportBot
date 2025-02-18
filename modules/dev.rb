module Dev
  module_function

  def call(data = nil)
    return 'Choose a command' if data.nil?

    get_pim_data
    case data
    when 'PIM'
      self.get_pim_data
    end
  end


  def get_pim_data
    user_id = 119360242
    token = '8104651007:AAEzZO8dX17myRC7kLLLYStSEWRwQzSH5Nk'
    bot = Telegram::Bot::Client.new(token)

    prepared_result = {
      type: "article",
      id: "unique-id-123",
      title: "Пример статьи",
      input_message_content: {
        message_text: "Это подготовленное inline-сообщение #{Time.now}"
      }
    }

    res = bot.api.savePreparedInlineMessage(
      user_id: user_id,
      result: prepared_result.to_json,
      allow_user_chats: true,
      allow_group_chats: true,
      allow_channel_chats: true
    )

    [
      '*Prepared Inline Message*',
      "ID: #{res.id}",
      "Expiration date: #{res.expiration_date}"
    ].join("\n")
  rescue StandardError
    'Something went wrong'
  end
end
