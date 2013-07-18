# Add custom filters here

'use strict';

ce2_filters = angular.module('CE2.filters',[])

ce2_filters.filter 'summary_comments', ->
  (comments) ->
    if comments
      comments = (comment for comment in comments when comment.type is "SummaryComment")

ce2_filters.filter 'conversation_comments', ->
  (comments) ->
    if comments
      comments = (comment for comment in comments when comment.type is "ConversationComment")

ce2_filters.filter 'from_now', ->
  (date) ->
    moment(date).fromNow()


ce2_filters.filter 'characters_remaining', ->
  (count) ->
    switch
      when count > 1 then "#{count} characters left"
      when count == 1 then "1 character left"
      when count == 0 then "No characters left"
      when count == -1 then "<span class='warn'>1 character over</span>"
      when count < -1 then "<span class='warn'>#{count} characters over</span>"

ce2_filters.filter 'days_remaining', ->
  (count) ->
    switch
      when count == 0 then "Ends today!!!"
      when count == 1 then "Only #{count} day remaining"
      when count <5 then "Only #{count} days remaining"
      else "#{count} days remaining"

ce2_filters.filter 'vote_count', ->
  (count) ->
    switch
      when count == 1 then "<div class='count'>#{count}</div><div class='lbl'>vote</div>"
      else "<div class='count'>#{count}</div><div class='lbl'>votes</div>"
