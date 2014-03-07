class MultiCriteriaAnalysis < ActiveRecord::Base
  attr_accessible :agenda_id, :title, :description

  has_many :options, class_name: 'McaOption', dependent: :destroy
  has_many :criteria, class_name: 'McaCriteria', dependent: :destroy
  belongs_to :agenda

  def self.coord_evaluation_data(params)
    if [5,51].include?(params['mca_id'].to_i)
      return MultiCriteriaAnalysis.coord_combined_evaluation_data(params)

    end


    mca = MultiCriteriaAnalysis.find( params['mca_id'] )
    data = mca.attributes
    data[:page_title] = params['page_title']
    data[:options] = []
    mca.options.includes(:evaluations => [:ratings, :user]).sort{|a,b| a.order_id <=> b.order_id}.each do |option|
      option_attrs = option.attributes
      option_attrs[:evaluations] = []
      option.evaluations.each do |evaluation|
        if (params['mode'] != 'plenary' || evaluation.status == 'plenary') && evaluation.status != 'deleted'
          eval_attrs = evaluation.attributes
          eval_attrs[:last_name] = evaluation.user.last_name
          eval_attrs[:user_id] = evaluation.user.id
          eval_attrs[:category] = evaluation.category
          eval_attrs[:ratings] = {}
          evaluation.ratings.each do |rating|
            eval_attrs[:ratings][rating.mca_criteria_id] = rating.rating
          end
          option_attrs[:evaluations].push( eval_attrs )
        end
      end
      data[:options].push( option_attrs ) unless (params['mode'] == 'plenary' && option_attrs[:evaluations].size == 0)
    end
    data[:criteria] = []
    mca.criteria.sort{|a,b| a.order_id <=> b.order_id}.each do |criteria|
      data[:criteria].push( criteria.attributes )
    end
    data[:current_timestamp] = Time.new.to_i
    data
  end

  def self.group_evaluation_data(params)
    mca = MultiCriteriaAnalysis.find( params['mca_id'] )

    option_ids = mca.options.pluck(:id)

    if params['mode'] == 'plenary'
      evaluations = McaOptionEvaluation.where(user_id: params["current_user"].id, mca_option_id: option_ids, status: 'plenary').includes(:mca_option, :ratings)
    else
      evaluations = McaOptionEvaluation.where(user_id: params["current_user"].id, mca_option_id: option_ids).includes(:mca_option, :ratings)
      evaluations.reject!{|e| e.status == 'plenary'}
    end

    data = mca.attributes
    data[:page_title] = params['page_title']
    data[:evaluations] = []
    evaluations.sort{|a,b| a.order_id <=> b.order_id}.each do |evaluation|
      if evaluation.status != 'deleted'
        evaluation_attrs = evaluation.attributes
        evaluation_attrs[:title] = evaluation.mca_option.title
        evaluation_attrs[:project_id] = evaluation.mca_option.details['project_id']
        evaluation_attrs[:ratings] = {}
        evaluation.ratings.each do |rating|
          evaluation_attrs[:ratings][rating.mca_criteria_id] = rating.rating
        end
        data[:evaluations].push( evaluation_attrs )
      end
    end
    data[:criteria] = []
    mca.criteria.sort{|a,b| a.order_id <=> b.order_id}.each do |criteria|
      data[:criteria].push( criteria.attributes )
    end
    data[:current_timestamp] = Time.new.to_i
    data
  end

  def self.delete_mca(mca_ids)
    raise "CivicEvolution::McaCannotBeDeleted in PROD" unless Rails.env.development?
    mca_ids.each do |mca_id|
      begin
        mca = MultiCriteriaAnalysis.find(mca_id)
      rescue
        return
      end
      mca.criteria.each do |criteria|
        criteria.ratings.destroy_all
      end
      mca.criteria.destroy_all

      mca.options.each do |option|
        option.evaluations.destroy_all
      end
      mca.options.destroy_all
      mca.destroy
    end
  end





  def self.coord_combined_evaluation_data(params)
    mca = MultiCriteriaAnalysis.find( params['mca_id'] )
    agenda = mca.agenda
    mca_ids = agenda.details['mca_ids']

    source_keys = {
      2 => 'CGG',
      44 => 'CGG',
      3 => 'COM',
      45 => 'COM',
      4 => 'ADD',
      46 => 'ADD'
    }

    data = mca.attributes
    data[:page_title] = "Multi Criteria Analysis Results for Combined Projects"
    data[:options] = []

    criteria_map = {}

    data[:criteria] = []
    MultiCriteriaAnalysis.find( mca_ids[0] ).criteria.sort{|a,b| a.order_id <=> b.order_id}.each do |criteria|
      data[:criteria].push( criteria.attributes )
      criteria_map[ criteria.title ] = criteria.id
    end

    MultiCriteriaAnalysis.where(id: mca_ids ).each do |mca|
      source_key = source_keys[mca.id]
      mca.options.includes(:evaluations => [:ratings, :user]).sort{|a,b| a.order_id <=> b.order_id}.each do |option|
        option_attrs = option.attributes
        option_attrs[:evaluations] = []
        option_attrs['source_key'] = source_key
        #option_attrs['details']['project_id'] = "#{source_key}-#{option_attrs['details']['project_id']}"

        criteria_convert_map = {}
        mca.criteria.sort{|a,b| a.order_id <=> b.order_id}.each do |criteria|
          criteria_convert_map[criteria.id] = criteria_map[ criteria.title ]
        end

        option.evaluations.each do |evaluation|
          if evaluation.status != 'deleted'
            eval_attrs = evaluation.attributes
            eval_attrs[:last_name] = evaluation.user.last_name
            eval_attrs[:user_id] = evaluation.user.id
            eval_attrs[:category] = evaluation.category
            eval_attrs[:ratings] = {}
            evaluation.ratings.each do |rating|

              eval_attrs[:ratings][  criteria_convert_map[ rating.mca_criteria_id ]  ] = rating.rating
            end
            option_attrs[:evaluations].push( eval_attrs )
          end
        end
        data[:options].push( option_attrs ) unless option_attrs[:evaluations].size == 0
      end
    end

    data[:current_timestamp] = Time.new.to_i
    data
  end

  def add_criteria(title)
    criteria_stack = []
    title.split("\n").each do |criteria_title|
      criteria = self.criteria.create title: criteria_title
      criteria_stack.push( criteria.attributes )
    end
    criteria_stack
  end

  def add_option(title)
    options_stack = []
    title.split("\n").each do |criteria_title|
      pcs = criteria_title.split('#',2)
      if pcs.size == 1
        category = ''
        option_title = pcs[0]
      else
        option_title = pcs[1]
        category = pcs[0]
      end
      option = self.options.create title: option_title, category: category
      Rails.logger.debug "#{pp option.attributes}"
      options_stack.push( option.attributes )
    end
    options_stack
  end

  def update(key, value)
    Rails.logger.debug "MCA update key: #{key}, value: #{value}"
    case key
      when 'criteria_order'
        self.update_criteria_order( value )
        {ack: 'ok', key: key, value: value}
      when 'options_order'
        self.update_options_order( value )
        {ack: 'ok', key: key, value: value}
      when 'title'
        self.update_attribute(:title, value)
        value
      else
        Rails.logger.debug "MultiCriteriaAnalysis.update doesn't know what to do with key: #{key}"
        {ack: 'FAIL-UNKNOWN', key: key, value: value}
    end
  end

  def update_criteria_order( ordered_ids )
    ordered_ids.reject!{|id| id.to_i == 0}

    if !( ordered_ids.nil? || ordered_ids.empty?)
      ctr = 0
      order_string = ordered_ids.map{|o| "(#{ctr+=1},#{o})" }.join(',')

      sql =
          %Q|UPDATE mca_criteria SET order_id = new_order_id
FROM ( SELECT * FROM (VALUES #{order_string}) vals (new_order_id,mca_criteria_id)	) t
WHERE id = t.mca_criteria_id AND multi_criteria_analysis_id = #{self.id} |
      Rails.logger.debug "update_criteria_order with sql: #{sql}"
      ActiveRecord::Base.connection.update_sql(sql)

      # return the ordered ids as a hash that allows me to look up the order_id by comment_id to resort on browser
      ids_order_id = {}
      # the order_ids start from 1, not 0
      ordered_ids.each_index{ |i| ids_order_id[ordered_ids[i]] = i+1 }
      ids_order_id
    end
  end

  def update_options_order( ordered_ids )
    ordered_ids.reject!{|id| id.to_i == 0}

    if !( ordered_ids.nil? || ordered_ids.empty?)
      ctr = 0
      order_string = ordered_ids.map{|o| "(#{ctr+=1},#{o})" }.join(',')

      sql =
          %Q|UPDATE mca_options SET order_id = new_order_id
FROM ( SELECT * FROM (VALUES #{order_string}) vals (new_order_id,mca_option_id)	) t
WHERE id = t.mca_option_id AND multi_criteria_analysis_id = #{self.id} |
      Rails.logger.debug "update_options_order with sql: #{sql}"
      ActiveRecord::Base.connection.update_sql(sql)

      # return the ordered ids as a hash that allows me to look up the order_id by comment_id to resort on browser
      ids_order_id = {}
      # the order_ids start from 1, not 0
      ordered_ids.each_index{ |i| ids_order_id[ordered_ids[i]] = i+1 }
      ids_order_id
    end
  end

end
