class CreateAgendas < ActiveRecord::Migration
  def change
    create_table :agendas do |t|
      t.string :title
      t.text :description
      t.string :code
      t.string :access_code
      t.string :template_name
      t.boolean :list
      t.hstore :status

      t.timestamps
    end
  end
end
