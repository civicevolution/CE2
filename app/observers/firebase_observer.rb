class FirebaseObserver < ActiveRecord::Observer

  observe :comment
  
  def after_create(model)

    #Firebase.auth = "LHp51r7znXmO09dACFIz4TLPp7zbrdMHPtVkHua2"  
    Firebase.base_uri = 'https://civicevolution.firebaseio.com/issues/7/updates'  
    response = Firebase.push '', model.as_json_for_firebase( action: "create" )
    
    #Rails.logger.debug "In FirebaseObserver after_create model: #{model.inspect}"
  end

  def after_update(model)
    Firebase.base_uri = 'https://civicevolution.firebaseio.com/issues/7/updates'  
    response = Firebase.push '', model.as_json_for_firebase( action: "update" )
    #Rails.logger.debug "In FirebaseObserver after_update model: #{model.inspect}"
  end

end