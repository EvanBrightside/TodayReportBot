module Rubyweekly
  module_function

  def call
    response = Nokogiri::HTML(URI.open('https://rubyweekly.com/', 'User-Agent' => @user_agent))
    doc = response.css('.main p a').attr('href').text
    "https://rubyweekly.com#{doc}"
  rescue StandardError
    'Something wrong / You can check it on https://rubyweekly.com'
  end
end
