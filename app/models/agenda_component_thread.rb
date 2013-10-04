class AgendaComponentThread < ActiveRecord::Base

  attr_accessible :agenda_id, :parent_id, :child_id

  belongs_to :agenda
  belongs_to :child_agenda_components, class_name: "AgendaComponent", foreign_key: :child_id
  belongs_to :parent_agenda_components, class_name: "AgendaComponent", foreign_key: :parent_id

  before_create :set_order_id_for_child_comment, unless: Proc.new{|ct| ct.order_id}

  def set_order_id_for_child_comment
    # set order_id to the max order_id +1 for this conversation, starting at 1
    self.order_id = AgendaComponentThread.where(parent_id: self.parent_id).maximum(:order_id).try{ |max| max + 1 } || 1
  end

end
