# custom initialization code for app

Paperclip.interpolates :res_base do |attachment, style|
  RES_BASE
end

Paperclip.interpolates('user_code') do |attachment, style|
  attachment.instance.user.code.parameterize
end

CIVICEVOLUTION_CONFIGURATION = YAML.load_file("#{Rails.root}/config/civicevolution.yml")
CONVERSATION_PROPERTIES = CIVICEVOLUTION_CONFIGURATION['CONVERSATION_PROPERTIES'].dup
