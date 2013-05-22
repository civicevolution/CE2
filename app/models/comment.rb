require 'differ'
class Comment < ActiveRecord::Base
  #include Modules::FirebaseConnect

  def active_model_serializer
    CommentSerializer
  end

  attr_accessor :attachment_ids, :my_rating

  has_paper_trail class_name: 'CommentVersion', on: [:update], only: [:text, :order_id], version: :paper_trail_version,
                  skip: [:type, :user_id, :conversation_id, :status, :order_id, :purpose, :references, :created_at, :updated_at, :ratings_cache]


  belongs_to :author,  -> { select :id, :first_name, :last_name}, :class_name => 'User', :foreign_key => 'user_id',  :primary_key => 'id'  #, photo_file_name'

  belongs_to :conversation

  has_many :attachments, :as => :attachable

  has_many :ratings, :as => :ratable

  attr_accessible :type, :user_id, :conversation_id, :text, :version, :status, :order_id, :purpose, :references, :attachment_ids

  before_update :increment_comment_version
  after_save :associate_attachments
  before_create :initialize_ratings_cache_to_zeros

  def increment_comment_version
    self.version += 1
    true
  end

  def associate_attachments
    # associate the attachment records to this comment if attachment is owned by user and is not associated to another record
    return unless attachment_ids
    attachments << Attachment.where(user_id: user_id, attachable_id: 0, attachable_type: 'Undefined', id: attachment_ids.scan(/\d+/).map(&:to_i) )
  end

  def initialize_ratings_cache_to_zeros
    self.ratings_cache = [0,0,0,0,0,0,0,0,0,0]
    true
  end

  validates :type, :user_id, :conversation_id, :text, :version, :status, :order_id, :presence => true

  validate :my_test

  def my_test
    #errors.add(:text, "My text error message")
    #errors.add(:name, "My name error message")
    #errors.add(:text, "must be at least #{range[1]} characters") unless length >= range[1].to_i
    #errors.add(:text, "must be no longer than #{range[2]} characters") unless length <= range[2].to_i
    #false
  end


  def history_diffs

    Differ.format = :html

    # create an array of the version details
    # extract the version #, text and time from the comment_versions table using reify
    version_details = self.versions.map do |ver|
      com_ver = ver.reify
      { text: com_ver.text, version: com_ver.version, created_at: ver.created_at}
    end

    # I want to display newest version and diffs first
    version_details.reverse!

    #process the version details into an array of diffs
    # for each version generate the diff with from the next version, if it exists

    # first diff is the current text
    diffs = [ { version: 'Current', html_diff: self.text, created_at: self.updated_at } ]

    # next diff is between current text and the first stored version
    diffs << { version: 'Current',
               html_diff: Differ.diff_by_word(self.text, version_details[0][:text]).to_s,
               created_at: self.created_at }

    # now iterate through the remaining versions, and then show initial version
    version_details.each_with_index do |ver,i|
      prev_ver = version_details[i+1]
      if prev_ver
        #puts "i: #{i}, ver: #{ver[:version]}: #{ver[:text]} PREV ver: #{prev_ver[:version]}: #{prev_ver[:text]}"
        diffs << { version: ver[:version],
                   #html_diff: "new: #{ver[:text]}, old: #{prev_ver[:text]}",
                   html_diff: Differ.diff_by_word(ver[:text], prev_ver[:text]).to_s,
                   created_at: ver[:created_at] }
      else
        #puts "i: #{i}, ver: #{ver[:version]}: #{ver[:text]} NO PREV ver!"
        diffs << { version: 'Original', html_diff: ver[:text], created_at: ver[:created_at] }
      end
    end

    diffs

  end



  protected
  def as_json_for_firebase( action = "create" )
    #data = as_json root: false, except: [:user_id]
    data = CommentSerializer.new( self )
    { class: self.class.to_s, action: action, data: data, source: "RoR-Firebase" }
  end

end
