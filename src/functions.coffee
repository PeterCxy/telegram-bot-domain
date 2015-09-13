whois = require 'node-whois'
{korubaku} = require 'korubaku'

exports.name = "domains"
exports.desc = "Domain tools"

exports.setup = (telegram, store, server) ->
	[
			cmd: 'whois'
			num: 1
			desc: 'Lookup the whois information of <domain>'
			act: (msg, domain) ->
				korubaku (ko) =>
					if msg.chat.title?
						telegram.sendMessage msg.chat.id, 'Only available in private chat'
					else
						[result] = yield lookup store, domain, ko.raw()
						telegram.sendMessage msg.chat.id, result
		,
			cmd: 'domain'
			num: 1
			desc: 'Check the availablity of <domain>'
			act: (msg, domain) ->
				korubaku (ko) =>
					[result] = yield lookup store, domain, ko.raw()
					if result.indexOf('No match for domain') >= 0
						telegram.sendMessage msg.chat.id, "Domain #{domain} has not been registered yet."
					else
						[_, name, ...] = /\nRegistrant Name: (.*?)\n/g.exec result
						[_, email, ...] = /\nRegistrant Email: (.*?)\n/g.exec result
						telegram.sendMessage msg.chat.id, "Domain #{domain} has been registered by #{name} (#{email})."
	]

lookup = (store, domain, callback) ->
	korubaku (ko) =>
		[err, result] = yield store.get 'whois', domain, ko.raw()
		if err? or !result? or result.trim() is ''
			result = yield whois.lookup domain, ko.default()
			yield store.put 'whois', domain, result, ko.default()
		callback result, domain
