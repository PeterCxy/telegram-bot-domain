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
						r1 = /\nRegistrant Name: (.*?)\n/g.exec result
						r2 = /\nRegistrant Email: (.*?)\n/g.exec result

						name = 'NaN'
						email = 'NaN'

						if r1? and r2? and r1.length > 1 and r2.length > 1
							name = r1[1]
							email = r2[1]
						else
							r3 = /\nDomain Owners \/ Registrant \nName: (.*?) \n/g.exec result
							if r3? and r3.length > 1
								name = r3[1]

						telegram.sendMessage msg.chat.id, "Domain #{domain} has been registered by #{name} (#{email})."
	]

lookup = (store, domain, callback) ->
	korubaku (ko) =>
		[err, result] = yield store.get 'whois', domain, ko.raw()
		if err? or !result? or result.trim() is ''
			result = yield whois.lookup domain, ko.default()
			yield store.put 'whois', domain, result, ko.default()
		callback result, domain
