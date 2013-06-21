class AddOrderIdToQuestions < ActiveRecord::Migration
  def change
    add_column :questions, :order_id, :integer
  end
end
