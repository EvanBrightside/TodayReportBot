module Rubyweekly
  module_function

  def call
    response = Nokogiri::HTML(open('http://rubyweekly.com/', 'User-Agent' => @user_agent))
    doc = response.css('.main p a').attr('href').text
    link = "http://rubyweekly.com#{doc}"
    feed = Nokogiri::XML(open(link, {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}))
    issues = feed.css('.el-item .item')
    rubyissues = []
    issues.map do |s|
      title = "*#{s.at_css('a').text.upcase}*"
      main_text = "`#{s.at_css('p').children.map(&:text)[1]}`"
      link = "[link](#{s.at_css('a')[:href]})"
      rubyissues << [title, main_text, link]
    end
    rubyissues.map { |a, s, d| [ a, s, ["#{d}\n"] ] }*"\n"
  rescue StandardError
    'Something wrong / You can check it on https://rubyweekly.com'
  end
end
