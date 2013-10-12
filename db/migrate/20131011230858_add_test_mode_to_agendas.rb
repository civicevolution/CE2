class AddTestModeToAgendas < ActiveRecord::Migration
  def change
    add_column :agendas, :test_mode, :boolean, default: true
  end
end
