class Conversation < ActiveRecord::Base
  def active_model_serializer
    ConversationSerializer
  end

  attr_accessible :question_id, :status
  attr_accessor :firebase_token

  belongs_to :question
  has_many  :comments, -> { includes author: :profile   }
  has_many  :conversation_comments, -> { includes author: :profile }
  has_many :summary_comments, -> { includes author: :profile }

  has_many :attachments, :as => :attachable

  validates :question_id, :status, :presence => true


  def self.reorder_summary_comments( id, ordered_ids )
    ordered_ids.reject!{|id| id.to_i == 0}

    if !( ordered_ids.nil? || ordered_ids.empty?)
      ctr = 0
      order_string = ordered_ids.map{|o| "(#{ctr+=1},#{o})" }.join(',')

      sql =
%Q|UPDATE comments SET order_id = new_order_id
FROM ( SELECT * FROM (VALUES #{order_string}) vals (new_order_id,comment_id)	) t
WHERE id = t.comment_id AND conversation_id = #{id} AND type = 'SummaryComment'|
      Rails.logger.debug "Use sql: #{sql}"
      ActiveRecord::Base.connection.update_sql(sql)

      # return the ordered ids as a hash that allows me to look up the order_id by comment_id to resort on browser
      ids_order_id = {}
      ordered_ids.each_index{ |i| ids_order_id[ordered_ids[i]] = i }
      ids_order_id
    end
  end

end
