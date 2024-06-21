module Delfin
  module_function

  def call
    'https://my.delfin.app/'
  rescue StandardError
    'Something wrong'
  end
end
