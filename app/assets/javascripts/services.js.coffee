#console.log("loading services.js.coffee");

services = angular.module("CE2.services", ["ngResource"])

services.factory "Comment", ["$resource", ($resource) ->
  $resource("/api/comments/:id", {id: "@id"}, {update: {method: "PUT"}})
]

services.factory "CommentData", ["$log", "Comment", ($log, Comment) ->
	comments: Comment.query(services.ok_func, services.err_func)
]


services.factory "FirebaseUpdates", ["$log", "CommentData", ($log, CommentData) ->
	process: (data) ->
		$log.log "process a FirebaseUpdate"
		temp.FirebaseUpdates.push data
		CommentData.comments.push
			id: data.id
			name: data.name
			text: data.text
			liked: data.liked
		
]
