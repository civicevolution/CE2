class AddDailyReportHourAndLastReportToConversations < ActiveRecord::Migration
  def change
    add_column :conversations, :daily_report_hour, :integer, default: 7
    add_column :conversations, :last_report_sent_at, :datetime
  end
end
