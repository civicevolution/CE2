class Report < ActiveRecord::Base

  attr_accessible :title, :source_type, :source_code, :layout, :version, :header, :settings, :user_id, :agenda_code
                  #:image, :image_file_name, :image_content_type, :image_file_size, :image_updated_at

  has_many :report_images, dependent: :destroy

  validates :title, presence: { message: 'You must enter a title' }

  def populate_new_report(params, current_user)
    self.user_id = current_user.id
    self.agenda_code = params[:agenda_code]
    self.title = params[:report_title]
    self.source_type = 'conversation'
    self.source_code = params[:conversation_code]
    self.layout = params[:layout]
    self.header = params[:header_text]
    self.settings = {
        hide_examples: params[:hide_examples],
        font_family: params[:font_family],
        font_size: params[:font_size],
        canvas_width: params[:canvas_width],
        max_canvas_height_first_block: params[:max_canvas_height_first_block],
        max_canvas_height_addtl_blocks: params[:max_canvas_height_addtl_blocks]
    }
    self.version = 1
    self.save!

    images = params.each_key.select{|key| key.match(/report-image-/) }
    multiple_images = images.size > 1

    params.each_key do |key|
      if key.match(/report-image-/)
        report_image = ReportImage.new
        report_image.image = params[key]
        if multiple_images
          report_image.image_file_name = "#{self.title.gsub(/\s/, "-").gsub(/[^\w&-]/,'').downcase[0..50]}-#{self.report_images.size + 1}.png"
        else
          report_image.image_file_name = "#{self.title.gsub(/\s/, "-").gsub(/[^\w&-]/,'').downcase[0..50]}.png"
        end
        self.report_images <<  report_image
      end
    end

    {
      id: self.id,
      title: self.title,
      report_images: self.report_images.map{|image| { title: image.image_file_name, url: image.image.url} }
    }
  end

end
