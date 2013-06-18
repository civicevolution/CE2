// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//

// require jquery-1.9.1
//= require underscore-min.js
//= require md5.js

//= require polyfills

//= require angular-1.1.5/angular
//= require angular-1.1.5/angular-resource
//= require angular-ui-states-0.0.1/angular-ui-states.js
//= require ui-bootstrap-tpls-0.2.0/ui-bootstrap-tpls-0.2.0.js
//= require firebase.js

//= require controllers.js
//= require directives.js
//= require filters.js
//= require services.js

//= require graph.js
//= require moment.js

//= require utilities.js
// require utilities_temp.js

//= require Markdown.Converter.js
//= require Markdown.Editor.js
//= require Markdown.Sanitizer.js
//= require bbcode.js


//= require ng-upload.js

// Don't use these for now
// require jquery-1.9.1
// require bootstrap
// require jquery_ujs

var temp = { FirebaseUpdates: [] }
setTimeout( function(){SVCS = angular.element(document.body).injector();}, 2000)