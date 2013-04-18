#console.log("loading services.js.coffee");

services = angular.module("CE2.services", ["ngResource"])

services.factory "Comment", ["$resource", ($resource) ->
  $resource("/api/comments/:id", {id: "@id"}, {update: {method: "PUT"}})
]

services.factory "CommentData", ["$log", "Comment", ($log, Comment) ->
	comments: Comment.query(services.ok_func, services.err_func)
]


services.factory "FirebaseUpdates", [ "CommentData", ( CommentData) ->
	process: (data) ->
		new_com =
			id: data.data.id
			name: data.data.name
			text: data.data.text
			liked: data.data.liked
		
		CommentData.comments.forEach (com, i) ->
			if com.id == data.data.id
				CommentData.comments[i] = new_com
				return new_com = null
		CommentData.comments.push new_com if new_com
]
