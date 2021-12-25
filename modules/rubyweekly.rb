module Rubyweekly
  module_function

  def call
    response = Nokogiri::HTML(URI.open('https://rubyweekly.com/', 'User-Agent' => @user_agent))
    doc = response.css('.main p a').attr('href').text
    link = "https://rubyweekly.com#{doc}"
    feed = Nokogiri::XML(URI.open(link, { ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE }))
    collect_issues(feed.css('.el-item.item'))
  rescue StandardError
    'Something wrong / You can check it on https://rubyweekly.com'
  end

  def collect_issues(issues)
    rubyissues = []
    issues.map do |issue|
      title = "*#{issue.at_css('a').text.upcase}*"
      main_text = "`#{issue.at_css('p').children.map(&:text)[1]}`"
      link = "[link](#{issue.at_css('a')[:href]})"
      rubyissues << [title, main_text, link]
    end
    rubyissues.map { |title, main_text, link| [title, main_text, ["#{link}\n"]] } * "\n"
  end
end
