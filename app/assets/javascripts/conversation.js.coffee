# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/


app = angular.module("Conversation", ["ngResource"])

app.factory "Comment", ["$resource", ($resource) ->
  $resource("/comments/:id", {id: "@id"}, {update: {method: "PUT"}})
]

@ConversationCtrl = [ "$scope", "Comment", ($scope, Comment) ->	

	$scope.comments = Comment.query()
		
	$scope.addComment = ->
		comment = Comment.save( $scope.newComment )
		$scope.comments.push( comment )
		$scope.newComment = {}
		
	$scope.like = ->
		@comment.liked ?= false
		@comment.liked = not @comment.liked
		@comment.$update()
]		
		