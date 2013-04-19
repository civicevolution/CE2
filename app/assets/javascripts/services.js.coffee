#console.log("loading services.js.coffee");

services = angular.module("CE2.services", ["ngResource"])

services.factory "Comment", ["$resource", ($resource) ->
  $resource("/api/comments/:id", {id: "@id"}, {update: {method: "PUT"}})
]

services.factory "CommentData", ["$log", "Comment", "FirebaseUpdateRec", ($log, Comment, FirebaseUpdateRec) ->
	comments: Comment.query(services.ok_func, services.err_func)
	process_firebase: (data) -> 
		console.log("perform process_firebase")
		FirebaseUpdateRec.process this, 'comments', data
]


services.factory "FirebaseUpdateRec", [ ->
	process: (service, collection_name, data) ->
		if data.action == "destroy"
			service[collection_name].forEach (rec, i) ->
				if rec.id == data.data.id
					return service[collection_name].splice(i, 1)
		else
			new_rec = data.data
			service.comments.forEach (rec, i) ->
				if rec.id == new_rec.id
					service[collection_name][i] = new_rec
					return new_rec = null
			service[collection_name].push new_rec if new_rec
	]

services.factory "FirebaseUpdates", [ "CommentData", ( CommentData) ->
	process: (data) ->
		if data.action == "destroy"
			CommentData.comments.forEach (com, i) ->
				if com.id == data.data.id
					return CommentData.comments.splice(i, 1)

		else
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
