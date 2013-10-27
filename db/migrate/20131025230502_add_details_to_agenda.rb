class AddDetailsToAgenda < ActiveRecord::Migration
  def change
    add_column :agendas, :details, :json
  end
end
