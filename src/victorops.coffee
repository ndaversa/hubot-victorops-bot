# Description:
# Quickly page the person on call in victorops
#
# Dependencies:
# - coffee-script
# - node-fetch
# - moment
# - ical
# - fuzzy
# - underscore
#
# Configuration:
# HUBOT_VICTOROPS_POST_URL - REST Endpoint for Victorops
# HUBOT_VICTOROPS_TEAMS_MAP  `\{\"ops\":\"devops\",\"data\":\"data\"\}`
# HUBOT_VICTOROPS_TEAMS_ICAL `\{\"devops\":\"URL_TO_ICS\",\"data\":\"URL_TO_ICS\"\}`
#
# Commands:
#   hubot page oncall <optional message>
#   hubot whois oncall
#
# Author:
#   ndaversa

_ = require 'underscore'
fetch = require 'node-fetch'
moment = require 'moment'
ical = require 'ical'
fuzzy = require 'fuzzy'

module.exports = (robot) ->
  url = process.env.HUBOT_VICTOROPS_POST_URL
  teams = JSON.parse process.env.HUBOT_VICTOROPS_TEAMS_MAP
  calendars = JSON.parse process.env.HUBOT_VICTOROPS_TEAMS_ICAL

  parseJSON = (response) ->
    return response.json()

  checkStatus = (response) ->
    if response.status >= 200 and response.status < 300
      return response
    else
      error = new Error(response.statusText)
      error.response = response
      throw error

  lookupUser = (name) ->
    users = robot.brain.users()
    users = _(users).keys().map (id) ->
      user = users[id]
      id: id
      name: user.real_name || user.name

    results = fuzzy.filter name, users, extract: (user) -> user.name
    if results?.length is 1
      return "<@#{results[0].original.id}>"
    else
      return "<@#{name}>"

  whoIsOncall = (team, cb) ->
    now = moment()
    calendar = calendars[team]
    ical.fromURL calendar, {}, (err, data) ->
      events = _(data).keys().map (id) ->
        event = data[id]
        start: moment event.start
        end: moment event.end
        summary: event.summary
        id: id
      .filter (event) -> now.isBetween event.start, event.end

      if events.length is 1
        oncall = events[0]
      else
        events = events.filter (event) -> event.summary.indexOf('OVERRIDE') > -1
        if events.length is 1
          oncall = events[0]

      if oncall
        [ __, person ] = oncall.summary.match /(?:OVERRIDE:\s)?(.*)/
      cb person

  robot.respond /page oncall(?:\s+(.*))?/, (msg) ->
    [ __, message ] = msg.match
    room = msg.message.room
    team = teams[room]
    return msg.reply "You can only page for oncall in one of the following project channels:" + (" <\##{channel}>" for channel, team of teams) if not team

    whoIsOncall team, (person) ->
      if person
        fetch "#{url}#{team}",
          method: "POST"
          body: JSON.stringify
           message_type: "critical"
           state_message: "You have been paged by @#{msg.message.user.name} in ##{room}: #{message}"
        .then (res) ->
          checkStatus res
        .then (res) ->
          parseJSON res
        .then (json) ->
          msg.reply "Paged #{lookupUser person} whom is on call for the `#{team}` team in victorops"
        .catch (error) ->
          console.log "*[Error]* #{error}"
          msg.reply "I have failed at paging #{lookupUser person}. I am shamed"
      else
        msg.reply "I can't determine who is on call, please contact your friendly administrator"

  robot.respond /whois oncall/, (msg) ->
    room = msg.message.room
    team = teams[room]
    return msg.reply "You can only see who is oncall in the following project channels:" + (" <\##{channel}>" for channel, team of teams) if not team

    whoIsOncall team, (person) ->
      if person
        msg.reply "#{lookupUser person} is on duty for the `#{team}` team"
      else
        msg.reply "I can't determine who is on call, please contact your friendly administrator"
