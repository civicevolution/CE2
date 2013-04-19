#console.log("loading services.js.coffee");

services = angular.module("CE2.services", ["ngResource"])

services.factory "Comment", ["$resource", ($resource) ->
  $resource("/api/comments/:id", {id: "@id"}, {update: {method: "PUT"}})
]

services.factory "CommentData", ["$log", "Comment", "FirebaseUpdateRec", ($log, Comment, FirebaseUpdateRec) ->
	comments: Comment.query(services.ok_func, services.err_func)
	process_firebase: (data) -> 
		#console.log("perform process_firebase")
		FirebaseUpdateRec.process this, 'comments', data
]


services.factory "FirebaseUpdateRec", [ ->
	process: (service, collection_name, data) ->
		if data.action == "destroy"
			for rec, index in service[collection_name]
				if rec.id == data.data.id
					return service[collection_name].splice(index, 1)
		else
			new_rec = data.data
			for rec, index in service[collection_name]
				if rec.id == new_rec.id
					service[collection_name][index] = new_rec
					new_rec = null
					break
			service[collection_name].push new_rec if new_rec
	]

services.factory "FirebaseUpdatesFromAngular", [ "CommentData", ( CommentData ) ->
	process: (data) ->
		switch data.class
			when "Comment" then CommentData.process_firebase data
			else console.error("FirebaseUpdatesFromAngular doesn't know how to process #{data.class}");
	]
