def dailynews
  items = Nokogiri::XML(open('https://meduza.io/rss/all', {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}))
  dailynews = []
  items.css('item')[0..5].map do |item|
    title = "*#{item.at_css('title').text.upcase}*"
    description = "`#{item.at_css('description').text}`"
    link = "[Полная статья](#{item.at_css('link').text})"
    dailynews << [title, description, link]
  end
  dailynews.map { |a, s, d| [ a, s, ["#{d}\n"] ] }*"\n"
end
