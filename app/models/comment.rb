require 'differ'
class Comment < ActiveRecord::Base
  include Modules::PostProcess

  def active_model_serializer
    CommentSerializer
  end

  attr_accessor :my_rating, :conversation_code, :in_reply_to_id, :in_reply_to_version, :bookmark

  has_paper_trail class_name: 'CommentVersion', on: [:update], only: [:text, :order_id], version: :paper_trail_version,
                  skip: [:type, :user_id, :conversation_id, :status, :order_id, :purpose, :references, :created_at, :updated_at, :ratings_cache]


  belongs_to :author,  -> { select :id, :first_name, :last_name, :code, :name}, :class_name => 'User', :foreign_key => 'user_id',  :primary_key => 'id'  #, photo_file_name'

  belongs_to :conversation

  has_many :ratings, :as => :ratable


  has_many :reply_to_targets, class_name: 'Reply', foreign_key: :comment_id
  has_many :reply_to_comments, through: :reply_to_targets, source: :reply_to_comments

  has_many :replies, class_name: 'Reply', foreign_key: :reply_to_id
  has_many :reply_comments, through: :replies, source: :reply_comments

  has_many :mentions, dependent: :delete_all

  attr_accessible :type, :user_id, :conversation_id, :text, :version, :status, :order_id, :purpose,
                  :references, :conversation_code, :in_reply_to_id, :in_reply_to_version

  after_initialize :read_previous_text_on_init
  before_update :increment_comment_version
  before_create :initialize_ratings_cache_to_zeros

  def read_previous_text_on_init
    @text = text
  end

  def increment_comment_version
    self.version += 1 if text != @text
    true
  end

  def initialize_ratings_cache_to_zeros
    self.ratings_cache = [0,0,0,0,0,0,0,0,0,0]
    true
  end

  validates :type, :user_id, :conversation_id, :version, :status, :order_id, :presence => true
  validates :purpose, presence: { message: 'Must select what you will share' }
  validates :text, length: { minimum: 20, too_short: "Must be at least %{count} characters"}
  #validates :text, length: { maximum: 1500, too_long: "Must be less than %{count} characters" }

  def is_new_comment?
    !persisted?
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

  def editable_by_user?(user)
    user_id == user.id
  end

  protected
  def as_json_for_firebase( action = "create" )
    #data = as_json root: false, except: [:user_id]
    data = CommentSerializer.new( self ).as_json
    { class: self.class.to_s, action: action, data: data, updated_at: Time.now.getutc, source: "RoR-Firebase" }
  end

end
