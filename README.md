# Hubot Victorops Bot
Quickly page the person on call in victorops

###Dependencies
- coffee-script
- node-fetch
- moment
- ical
- fuzzy
- underscore

###Configuration
`HUBOT_VICTOROPS_POST_URL` - REST Endpoint for Victorops
`HUBOT_VICTOROPS_TEAMS_MAP`  `\{\"ops\":\"devops\",\"data\":\"data\"\}`
`HUBOT_VICTOROPS_TEAMS_ICAL` `\{\"devops\":\"URL_TO_ICS\",\"data\":\"URL_TO_ICS\"\}`

###Commands
`hubot page oncall`
