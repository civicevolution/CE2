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

//= require jquery-1.9.1
//= require underscore-min.js
//= require md5.js

//= require polyfills

//= require angular-1.2.12/angular.js
//= require angular-1.2.12/angular-resource.js
//= require angular-1.2.12/angular-sanitize.js

//= require angular-ui-router-0.2.8/angular-ui-router.js
//= require ui-bootstrap-0.10.0/ui-bootstrap-tpls-0.10.0.js

//= require faye-browser.js

//= require controllers.js
//= require directives.js
//= require filters.js
//= require services.js

//= require graph.js
//= require reporter.js
//= require moment.js

// require utilities
// require utilities_temp.js

//= require Markdown.Converter.js
//= require Markdown.Editor.js
//= require Markdown.Sanitizer.js
//= require bbcode.js

//= require ng-grid/ng-grid-2.0.7.min.js
//= require ng-grid/ng-grid-csv-export.js
//= require ng-grid/ng-grid-flexible-height.js


// Don't use these for now
// require jquery-1.9.1
// require bootstrap
// require jquery_ujs

setTimeout( function(){SVCS = angular.element(document.body).injector();}, 2000)
