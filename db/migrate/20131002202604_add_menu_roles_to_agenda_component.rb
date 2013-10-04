class AddMenuRolesToAgendaComponent < ActiveRecord::Migration
  def change
    add_column :agenda_components, :menu_roles, :string, array: true
  end
end
