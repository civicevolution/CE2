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

    params.each_key do |key|
      if key.match(/report-image-/)
        report_image = ReportImage.new
        report_image.image = params[key]
        self.report_images <<  report_image
      end
    end

    if self.report_images.size > 1
      report_links = []
      report_links_ctr = 1
      self.report_images.each do |image|
        report_links.push( { title: "#{self.title}-#{report_links_ctr}", url: image.image.url})
        report_links_ctr += 1
      end

    else
      report_links = [ { title: self.title, url: self.report_images[0].image.url}]
    end
    report_links
  end

end
