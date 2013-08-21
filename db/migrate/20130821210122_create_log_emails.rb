class CreateLogEmails < ActiveRecord::Migration
  def change
    create_table :log_emails do |t|
      t.string :token
      t.string :email
      t.string :subject

      t.timestamps
    end
  end
end
