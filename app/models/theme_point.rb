class ThemePoint < ActiveRecord::Base

  attr_accessible :group_id, :voter_id, :theme_id, :points, :code

  def self.themes_points(themes)

    theme_ids = themes.map{|t| t[:theme_id]}
    theme_points = {}
    total_points = 0.to_f
    max_points = 0

    ThemePoint.select('theme_id, sum(points)').where(theme_id: theme_ids).group(:theme_id).each do |tp|
      theme_points[tp.theme_id] = tp.sum
      total_points += tp.sum
      max_points = tp.sum unless max_points > tp.sum
    end
    max_points = max_points.to_f

    themes.each do |theme|
      points = theme_points[theme[:theme_id]] || 0
      theme[:points] = points,
      theme[:percentage] = total_points > 0 ? (points/total_points*100).round : 0,
      theme[:graph_percentage] = max_points > 0 ? (points/max_points*100).round : 0
    end
    themes = themes.sort{|b,a| a[:points] <=> b[:points]}
  end
end
