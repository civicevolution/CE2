class AllocationTheme < ActiveRecord::Base

  attr_accessible :code, :theme_ids

  validate :code_is_unique, on: :create

  def allocation_themes
    themes = ThemeComment.where(id: self.theme_ids)
    allocation_themes = []
    ltr = 'A'
    self.theme_ids.each do |id|
      theme = themes.detect{|t| t.id == id}
      allocation_themes.push( {id: id, text: theme.text.gsub(/\[quote.*\/quote\]/,''), letter: ltr})
      ltr = ltr.succ
    end
    allocation_themes
  end

  def allocated_points
    themes = ThemeComment.where(id: self.theme_ids)
    theme_points = {}
    total_points = 0.to_f
    ThemePoint.select('theme_id, sum(points)').where(theme_id: self.theme_ids).group(:theme_id).each do |tp|
      theme_points[tp.theme_id] = tp.sum
      total_points += tp.sum
    end
    ltr = 'A'
    allocated_points = []
    self.theme_ids.each do |id|
      theme = themes.detect{|t| t.id == id}
      points = theme_points[id] || 0
      allocated_points.push( {id: id, letter: ltr, text: theme.text.gsub(/\[quote.*\/quote\]/,''),
                              points: points,
                              percentage: (points/total_points*100).round })
      ltr = ltr.succ
    end
    allocated_points.sort{|b,a| a[:points] <=> b[:points]}
  end

  def code_is_unique
    self.code = AllocationTheme.create_random_code
    while( AllocationTheme.where(code: self.code).exists? ) do
      self.code = AllocationTheme.create_random_code
    end
  end

  def self.create_random_code
    # I want each conversation to have a unique code for identification
    o =  [('a'..'z'),(0..9)].map{|i| i.to_a}.flatten
    (0...10).map{ o[rand(o.length)] }.join
  end

end
