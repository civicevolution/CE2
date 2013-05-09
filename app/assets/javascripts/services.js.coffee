#console.log("loading services.js.coffee");

services = angular.module("CE2.services", ["ngResource"])

services.factory 'User', [ "$http", "$window", ($http, $window) ->
  # a static method to retrieve current User
  name: "User"
  get: ->
    $http.get('/api/users/user.json').then (response) ->
      response.data

  sign_in: (dialog_scope, user, dialog) ->
    #console.log "User.sign_in  with data: #{user.email}/#{user.password}"
    $http.post('/users/sign_in.json', {user: user }).then(
      (response)->
        #console.log "signin received response"
        dialog.close()
        $window.location.reload()
    ,
    (reason) ->
      #console.log "signin received reason"
      dialog_scope.error_message = reason.data.error
    )

  sign_out: ->
    #console.log "User:sign_out"
    $http({method: 'DELETE', url: '/users/sign_out.json'}).then(
      (response)->
        #console.log "signout received response"
        $window.location.reload()
      ,
      (reason) ->
        console.log "signout received reason"
    )

  sign_up: (dialog_scope, user, dialog) ->
    #console.log "User.sign_up with credentials: #{user.name}/#{user.email}/#{user.password}"
    $http.post('/users.json', {user: user }).then(
      (response)->
        #console.log 'signup received response'
        dialog.close()
        $window.location.reload()
    ,
    (reason) ->
      #console.log 'signup received reason'
      if reason.data.errors
        dialog_scope.error_messages = reason.data.errors
      else
        console.log "a bigger error in sign up"
    )

  edit_profile: ->
    console.log 'User:edit_profile'
]

services.factory "Comment", ["$resource", ($resource) ->
  $resource("/api/comments/:id", {id: "@id"}, {update: {method: "PUT"}})
]

services.factory "CommentData", ["$log", "$http", "Comment", "FirebaseUpdateRec",
  ($log, $http, Comment, FirebaseUpdateRec) ->
    name: "CommentData"
    conversation: (conversation_id) ->
      # conversation(conversation_id) is called by the directive or controller that uses this data
      # this request returns a promise to the directive
      # a promise is also resolved in this original call
      # the promise segragates the data and sorts it into order
      # the then() call in the directive assigns the data components to this service
      # as well as assigning it to $scope
      # Firebase updates are pushed onto the data components on this service
      # which are bound to the scope of the directive and therefore the view
      # I couldn't get a reference to this service in the callback below so I
      # get the reference to this service in the directive and assign the data to the
      # service in the directives then()
      $http.get("/api/conversations/#{conversation_id}.json").then (response) ->
        if response.status is 200
          question: response.data.question
          summary_comments: (comment for comment in response.data.comments when comment.type is "SummaryComment")
            .sort((a,b)-> a.order_id - b.order_id)
          conversation_comments: (comment for comment in response.data.comments when comment.type is "ConversationComment")
            .sort((a,b)-> a.order_id - b.order_id)

    process_firebase: (data) ->
      FirebaseUpdateRec.process this, data

    persist_change_to_ror: (action, data, ok_cb, err_cb) ->
        _this._ok_cb = ok_cb
        _this._err_cb = err_cb
        action = 'update' if data.id
        Comment[action] data, (data,resp_headers_fn) =>
          _this._ok_cb() if _this._ok_cb
          FirebaseUpdateRec.process _this, {
            action: action
            class: "ConversationComment"
            data: data
            source: "#{action}Comment"
          }
        , err_func
]


services.factory "FirebaseUpdateRec", [ "$timeout", ($timeout) ->
  name: "FirebaseUpdateRec"
  process: (service, data) ->
    #console.log "FirebaseUpdateRec for #{data.class}"
    # The item arrays for updating are based on the class of the item
    # Only apply updates newer than the page load time
    if (new Date(data.data.updated_at).getTime() / 1000 ) - _timestamp > 0
      item_array = service["#{data.class}_array"]
      if not item_array
        # The item arrays are defined after the data has been received from RoR
        # defer the update until the array is established
        _this = this
        return $timeout ->
          _this.process( service, data )
        , 500
      #console.log "FirebaseUpdateRec do processing for #{data.class}"
      if data.action == "delete"
        for rec, index in item_array
          if rec.id == data.data.id
            return item_array.splice(index, 1)
      else
        new_rec = data.data
        for rec, index in item_array
          if rec.id == new_rec.id
            item_array[index] = new_rec
            new_rec = null
            break
        item_array.push new_rec if new_rec
]

# The models are updated from internal posts and external updates the same way
# e.g. when a comment is posted to the server it is also displayed locally by
# calling FirebaseUpdateRec.process
# Updates from firebase are also added to the bound data using FirebaseUpdateRec.process
# These updates are generated by RoR posting the update to firebase which then
# delivers it to the subscribed clients
# My local post will be processed into the model data twice, once after posting to RoR
# and a second time when RoR sends update to Firebase which sends update to all subscribers

services.factory "FirebaseUpdatesFromAngular", [ "CommentData", ( CommentData ) ->
  name: "FirebaseUpdatesFromAngular"
  process: (data) ->
    switch data.class
      when "SummaryComment" then CommentData.process_firebase data
      when "ConversationComment" then CommentData.process_firebase data
      when "Comment" then CommentData.process_firebase data
      else console.error("FirebaseUpdatesFromAngular doesn't know how to process #{data.class}");
]



###
  ok_func(data,resp_headers_fn) 
    data is the returned data
    resp_headers_fn('Server') (e.g.)
      "thin 1.5.1 codename Straight Razor"
###

ok_func = (data,resp_headers_fn) ->
  console.log("ok_func");    
  temp.data = data;


###
  err_func(error_object)
    error_object.config.data  (The data that was sent, e.g.)
      Resource {created_at: "2013-04-11T07:05:12Z", id: 18, liked: false, name: "Charley", text: "check it out"…}

    error_object.config.method: "PUT"
    error_object.config.url: "/comments/18" (The URL that was called)

    error_object.headers() >> Response headers returned (e.g.)
      error_object.headers('Server')
        "thin 1.5.1 codename Straight Razor"

    error_object.status
      500

    error_object.data (The error string that was returned e.g.)
      "ActiveRecord::RecordNotFound at /comments/18
      ============================================

      > Couldn't find Comment without an ID

      With full stack trace ...
###    

err_func = (error_object) ->
  reported_error = error_object.data
  key = ("#{name}" for name, msg of reported_error)[0]
  errors = reported_error[key]
  switch 
    when error_object.status is 504
      console.log "504 Gateway Time-out. The server didn't respond in time"

    else
      switch key
        when 'errors'
          error_message = ("Field: #{field}, Error: #{msg}" for field, msg of errors).join('\n')
          console.log error_message
        when 'system_error'
          console.log "System Error: #{errors}"
        else
          console.log "Don't know how to handle this error"
          #debugger
