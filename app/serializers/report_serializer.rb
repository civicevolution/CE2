class ReportSerializer < ActiveModel::Serializer
  attributes :id, :title, :updated_at, :report_images

  def report_images
    object.report_images.map{|image| {title: image.image_file_name, url: image.image.url }}
  end


end
