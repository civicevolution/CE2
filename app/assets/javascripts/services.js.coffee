#console.log("loading services.js.coffee");

services = angular.module("CE2.services", ["ngResource"])

services.factory "Comment", ["$resource", ($resource) ->
  $resource("/api/comments/:id", {id: "@id"}, {update: {method: "PUT"}})
]

services.factory "CommentData", ["$log", "Comment", "FirebaseUpdateRec", ($log, Comment, FirebaseUpdateRec) ->
	
	comments: Comment.query(services.ok_func, services.err_func)

	process_firebase: (data) -> 
		FirebaseUpdateRec.process this, 'comments', data
	
	persist_change_to_ror: (action, data, ok_cb, err_cb) ->
			_this._ok_cb = ok_cb
			_this._err_cb = err_cb
			Comment[action] data, (data,resp_headers_fn) =>
				_this._ok_cb() if _this._ok_cb
				FirebaseUpdateRec.process _this, 'comments', {
					action: action
					class: "Comment"
					data: data
					source: "#{action}Comment"
				}
			, err_func 
]


services.factory "FirebaseUpdateRec", [ ->
	process: (service, collection_name, data) ->
		if data.action == "delete"
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
