class AddRatingsArrayToComments < ActiveRecord::Migration
  def self.up
    execute "alter table comments add column ratings_cache int[]"
  end

  def self.down
    execute "alter table comments drop column ratings_cache"
  end
end

