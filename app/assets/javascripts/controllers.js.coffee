# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

bootstrap_CE2 = ->
	#console.log "In bootstrap_CE2"
	try
		angular.module('firebase')
		angular.bootstrap(document,["CE2"])
	catch error
		setTimeout bootstrap_CE2, 50
bootstrap_CE2()

#console.log("loading controllers.js.coffee")


ce2_app = angular.module("CE2", ["ngResource","CE2.services", "firebase"] )

ce2_app.config ($httpProvider) ->
	$httpProvider.defaults.headers.common["X-CSRF-TOKEN"] = 
		document.querySelectorAll('meta[name="csrf-token"]')[0].getAttribute('content')

ce2_app.controller( "ConversationCtrl", [ "$scope", "Comment", ($scope, Comment) ->	

	$scope.comments = Comment.query(ok_func, err_func)
		
	$scope.addComment = ->
		comment = Comment.save( $scope.newComment, ok_func, err_func )
		$scope.comments.push( comment )
		$scope.newComment = {}
		
	$scope.like = ->
		@comment.liked ?= false
		@comment.liked = not @comment.liked
		@comment.$update( ok_func, err_func)
] )		


ce2_app.controller( "ChatCtrl", [ "$scope", '$timeout', 'angularFireCollection', ($scope, $timeout, angularFireCollection) ->	
	
	el = document.getElementById("messagesDiv")
	url = 'https://civicevolution.firebaseio.com/issues/7/comments'
	$scope.messages = angularFireCollection url, ->
		#debugger
		$timeout ->
			el.scrollTop = el.scrollHeight

	
	$scope.username = 'Guest' + Math.floor(Math.random()*101)
	$scope.addMessage = ->
		#debugger
		$scope.messages.add {from: $scope.username, content: $scope.message}, ->
			el.scrollTop = el.scrollHeight
		$scope.message = ""

				
	$scope.test_link = ->
		#debugger
		console.log "I clicked 'test_link'"	
		
] )



###
	ok_func(data,resp_headers_fn) 
		data is the returned data
		resp_headers_fn('Server') (e.g.)
			"thin 1.5.1 codename Straight Razor"
###

ok_func = (data,resp_headers_fn) ->
	#console.log("ok_func");		


###
	err_func(error_object)
		error_object.config.data	(The data that was sent, e.g.)
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
					debugger

