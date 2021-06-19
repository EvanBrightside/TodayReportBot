module Currency
  module_function

  def call
    doc = Nokogiri::XML(
      URI.open('http://www.cbr.ru/scripts/XML_daily.asp?', { ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE })
    )
    us = doc.at_css('Valute[ID="R01235"]')
    us_charcode = us.at_css('CharCode').text
    us_value = us.at_css('Value').text
    eu = doc.at_css('Valute[ID="R01239"]')
    eu_charcode = eu.at_css('CharCode').text
    eu_value = eu.at_css('Value').text

    [
      '*Курсы валют на сегодня:*',
      "🇺🇸 1 #{us_charcode} = #{us_value[0..4]} RUB",
      "🇪🇺 1 #{eu_charcode} = #{eu_value[0..4]} RUB"
    ].join("\n")
  end
end
