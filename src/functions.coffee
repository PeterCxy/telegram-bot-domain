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
					info = parse domain, result

					if !info?
						telegram.sendMessage msg.chat.id, "Domain #{domain} has not been registered yet."
					else
						telegram.sendMessage msg.chat.id, "Domain #{domain} has been registered by #{info.name} (#{info.email})."
	]

lookup = (store, domain, callback) ->
	korubaku (ko) =>
		[err, result] = yield store.get 'whois', domain, ko.raw()
		if err? or !result? or result.trim() is ''
			[err, result] = yield whois.lookup domain, ko.raw()
			if !err? and result?
				yield store.put 'whois', domain, result, ko.default()
		callback result, domain

parse = (domain, info) ->
	lower = if info? then info.toLowerCase().trim() else ''
	if lower is '' or lower.indexOf('no match for') >= 0 or lower.indexOf('not found') >= 0
		return null

	suffix = domain[(domain.lastIndexOf('.') + 1)..]
	console.log "domain suffix #{suffix}"
	switch suffix
		when 'im' then  return parseIm info
		else return parseDef info

parseIm = (info) ->
	result =
		name: 'NaN'
		email: 'NaN'

	for line in info.split('\r\n')
		if line.startsWith 'Name:'
			result['name'] = line[6...].trim()
	
	return result

parseDef = (info) ->
	result =
		name: 'NaN'
		email: 'NaN'

	for line in info.split('\n')
		if line.startsWith 'Registrant Name:'
			result['name'] = line[17...].trim()
		else if line.startsWith 'Registrant Organization:'
			result['name'] = line[25...].trim()
		else if line.startsWith 'Registrant Email:'
			result['email'] = line[18...].trim()
	
	return result
