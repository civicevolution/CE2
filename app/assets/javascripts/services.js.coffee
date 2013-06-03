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

services.factory "Issue", [ ->
  data:
    issue_data
]


services.factory "ConversationData", ["$http", "FirebaseService",
  ($http, FirebaseService) ->
    name: "ConversationData"
    conversation: (conversation_id) ->
      # conversation(conversation_id) is called by the directive or controller that uses this data
      # this request returns a promise to the directive
      # a promise is also resolved in this original call
      # the promise segragates the data and sorts it into order
      # the then() call in the directive assigns the data components to this service
      # as well as assigning it to $scope
      # and subscribing to Firebase updates on this data
      # The updates are broadcast and controllers can update their scope data
      # see description below with FirebaseService
      $http.get("/api/conversations/#{conversation_id}.json").then (response) ->
        if response.status is 200
          #console.log "conversation_id: #{conversation_id}"
          # extract and setup some data for the directive controller
          firebase_token: response.data.firebase_token
          question: response.data.question
          summary_comments: (comment for comment in response.data.comments when comment.type is "SummaryComment")
            .sort((a,b)-> a.order_id - b.order_id)
          conversation_comments: (comment for comment in response.data.comments when comment.type is "ConversationComment")
            .sort((a,b)-> a.order_id - b.order_id)

]

services.factory "CommentData", ["$log", "$http", "Comment", "$rootScope",
  ($log, $http, Comment, $rootScope) ->
    name: "CommentData"

    history: (comment_id) ->
      console.log "Retrieve history for comment #{comment_id}"
      $http.get("/api/comments/#{comment_id}/history").then (response) ->
        response.data

    persist_change_to_ror: (action, data, ok_cb, err_cb) ->
        _this._ok_cb = ok_cb
        _this._err_cb = err_cb
        action = 'update' if data.id
        Comment[action] data, (data,resp_headers_fn) =>
          _this._ok_cb() if _this._ok_cb
          # broadcast this new item available that needs an update
          #console.log "broadcast this update"
          $rootScope.$broadcast "#{data.type}_update", {
            action: action
            class: data.type
            data: data
            source: "#{action}Comment"
          }
        , err_func

    persist_rating_to_ror: (comment_id, rating) ->
      #console.log "send rating to RoR id: #{comment_id} with rating #{rating}"
      $http.post("/comments/#{comment_id}/rate/#{rating}.json")

]

services.factory "AttachmentData", ["$log", "$http",
  ($log, $http) ->
    name: "AttachmentData"
    delete_attachment: (attachment_id) ->
      #console.log "AttachmentData:destroy_attachment id: #{attachment_id}"
      $http.delete("/api/attachments/#{attachment_id}.json")

]

# The controllers are responsible for requesting their data and storing it to scope
# The data is requested from a service
# In the callback, the controllers assigns the data to a scope object
# The models are updated from internal posts and external updates the same way
# e.g. when a comment is posted to the server it is also displayed locally by
# by broadcasting an update
# The controllers registers listeners for events that relate to their scope data
# When the controller receives an event notification about its scope data, it updates its collection
# using FirebaseService.process_update(item_array, data)
# Updates from firebase are also added to the bound data
# When child_added is detected, the event is broadcast with the data
# again, the controller listens for the event and then calls FirebaseService.process_update(item_array, data)
# These updates are generated by RoR posting the update to firebase which then
# delivers it to the subscribed clients
# My local post will be processed into the model data twice, once after posting to RoR
# and a second time when RoR sends update to Firebase which sends update to all subscribers
# The updates are idempotent, so multiple updates don't matter

services.factory "FirebaseService", [ "$timeout", "$rootScope", ($timeout, $rootScope ) ->
  name: "FirebaseService"
  initialize_source: (url, token) ->
    #console.log "Firebase.initialize_source a new Firebase Update Source with"
    #console.log "firebase url: #{url}"
    #console.log "firebase token: #{token}"
    conversation_updates_ref = new Firebase(url);
    conversation_updates_ref.auth( token )
    conversation_updates_ref.on 'child_added', (data) ->
      $rootScope.$broadcast( "#{data.val().class}_update", data.val() )

  process_update: (item_array, data) ->
    #console.log "Firebase.process_update for #{data.class}"
    # Only apply updates newer than the page load time
    update_all = false
    if update_all || (Date.fromISO(data.data.updated_at).getTime() / 1000 ) - _timestamp > 0
      if data.action == "delete"
        for rec, index in item_array
          if rec.id == data.data.id
            return item_array.splice(index, 1)
      else
        new_rec = data.data
        #console.log "looking at data with id: #{new_rec.id} and text: #{new_rec.text}"
        for rec, index in item_array
          if rec.id == new_rec.id
            item_array[index][prop] = new_rec[prop] for prop of new_rec when not prop.match(/^\$/)
            new_rec = null
            break
        if new_rec
          new_obj = {}
          new_obj[prop] = new_rec[prop] for prop of new_rec when not prop.match(/^\$/)
          item_array.push new_obj
      $rootScope.$$phase || $rootScope.$apply();
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
