def devby
  items = Nokogiri::XML(open('https://dev.by/rss', {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}))
  devby = []
  items.css('entry')[0..5].map do |item|
    title = "*#{item.at_css('title').text.upcase}*"
    description = "`#{item.at_css('summary').children[0].text.gsub(/\<(.*?)\>|&mdash;|&#8203;/i,"").gsub(/&nbsp;|&laquo;|&raquo;/i," ").split("\n")[0]}`"
    link = "[Полная статья](#{item.at_css('link').attributes['href'].value})"
    devby << [title, description, link]
  end
  devby.map { |a, s, d| [ a, s, ["#{d}\n"] ] }*"\n"
end
