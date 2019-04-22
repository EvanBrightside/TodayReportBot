def currency
  doc = Nokogiri::XML(open("http://www.cbr.ru/scripts/XML_daily.asp?", {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}))
  us = doc.at_css('Valute[ID="R01235"]')
  us_charcode = us.at_css('CharCode').text
  us_value = us.at_css('Value').text
  eu = doc.at_css('Valute[ID="R01239"]')
  eu_charcode = eu.at_css('CharCode').text
  eu_value = eu.at_css('Value').text

  bitcoin_url = 'https://api.coinmarketcap.com/v1/ticker/bitcoin/'
  bitcoin_response = HTTParty.get(bitcoin_url)
  bitcoin_h = bitcoin_response.parsed_response.first
  usd_bt = bitcoin_h["price_usd"]

  ethereum_url = 'https://api.coinmarketcap.com/v1/ticker/ethereum/'
  ethereum_response = HTTParty.get(ethereum_url)
  ethereum_h = ethereum_response.parsed_response.first
  usd_et = ethereum_h["price_usd"]

  ripple_url = 'https://api.coinmarketcap.com/v1/ticker/ripple/'
  ripple_response = HTTParty.get(ripple_url)
  ripple_h = ripple_response.parsed_response.first
  usd_rp = ripple_h["price_usd"]

  [
    '*Курсы валют на сегодня:*',
    "🇺🇸 1 #{us_charcode} = #{us_value} RUB",
    "🇪🇺 1 #{eu_charcode} = #{eu_value} RUB",
    "🔶 1 BTC = #{usd_bt} USD",
    "🔷 1 ETH = #{usd_et} USD",
    "◼️ 1 XRP = #{usd_rp} USD"
  ]*"\n"
end
