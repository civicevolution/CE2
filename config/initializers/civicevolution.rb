# custom initialization code for app

#Paperclip.interpolates :ape_code do |attachment, style|
#  attachment.instance.ape_code
#end

Paperclip.interpolates :res_base do |attachment, style|
  RES_BASE
end