class Rating < ActiveRecord::Base
  belongs_to :ratable, :polymorphic => true

  attr_accessible :user_id, :rating, :version

  after_initialize :read_previous_rating
  around_save :update_ratings_cache_on_ratable_around_save

  scope :for_user, -> (userid) { where("user_id = ?", userid)}

  def read_previous_rating
    @index_for_previous_rating = new_record? ? nil : ((rating-1)/10).floor
  end

  def update_ratings_cache_on_ratable_around_save
    self.version = ratable.version
    yield
    index_for_new_rating = ( (rating-1)/10).floor
    if index_for_new_rating != @index_for_previous_rating
      ratings_cache = ratable.ratings_cache
      ratings_cache[@index_for_previous_rating] -= 1 if @index_for_previous_rating
      ratings_cache[index_for_new_rating] += 1
      ratable.update_column(:ratings_cache, "{#{ratings_cache.join(',')}}" )
      # using update_column to prevent update of updated_at field means callbacks are skipped
      ratable.send_to_firebase if ratable.respond_to? :send_to_firebase
    end
  end
end
