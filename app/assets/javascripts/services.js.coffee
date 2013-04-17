#console.log("loading services.js.coffee");

services = angular.module("CE2.services", ["ngResource"])

services.factory "Comment", ["$resource", ($resource) ->
  $resource("/api/comments/:id", {id: "@id"}, {update: {method: "PUT"}})
]

