module Dailynews
  module_function

  def call
    items = Nokogiri::XML(open('https://meduza.io/rss/all', { ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE }))
    dailynews = []
    items.css('item')[0..5].map do |item|
      title = "*#{item.at_css('title').text.upcase}*"
      link = "[Полная статья](#{item.at_css('link').text})"
      dailynews << [title, link]
    end
    dailynews.map { |title, link| [[title, "#{link}\n"]] } * "\n"
  end
end
