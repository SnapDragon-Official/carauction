ESX = nil

-- ############################### ONLY CHANGE THIS PART ############
auctiontime = 140000
-- ######################### TIME IN MILISECONDS ##################
--[[carroleiloado = nil
valorleilao = nil--]]
logs = true
leilao = {}
leilao.temporestante = 0
leilao.running = false
maiorlicitacao = {}
licitacoes = {}
infoleilao = nil
teste = true

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

Citizen.CreateThread(function()
	while true do
		Wait(100)
		if leilao.temporestante ~= nil then
			Wait(1000)
			if leilao.temporestante == 1000 then
				acabarleilao()
				leilao.temporestante = nil
			else
				leilao.temporestante = leilao.temporestante - 1000
			end
		end
	end
end)

function matifp(mensagem)
	if logs == true then
		print('matif_leilaocarros: ' .. mensagem)
	end
end

ESX.RegisterServerCallback('matif_leilaocarros:cb:getcarros', function(source, cb, KindOfVehicle)
	local identifier = GetPlayerIdentifiers(source)[1]
	MySQL.Async.fetchAll("SELECT * FROM owned_vehicles WHERE owner = @identifier", {
		['@identifier'] = identifier
	}, function(result)
		cb(result)
	end)
end)

ESX.RegisterServerCallback('matif_leilaocarros:cb:getinfo', function(source, cb, a)
	local model = a
	MySQL.Async.fetchScalar("SELECT name FROM vehicles WHERE model = @model", {
		['@model'] = model
	}, function(result)
		cb(result)
	end)
end)


function acabarleilao()
	if not table.empty(licitacoes) then
		valor = maiorlicitacao.valor
		print(maiorlicitacao.identificador)
		local xPlayer = ESX.GetPlayerFromIdentifier(maiorlicitacao.identificador)
		local pPlayer = ESX.GetPlayerFromIdentifier(leilao.identifier)
		while xPlayer == nil and pPlayer == nil do
			Citizen.Wait(200)
		end
		print('started')
		if xPlayer ~= nil and pPlayer ~= nil then
			if xPlayer.getBank() > valor then
				xPlayer.removeAccountMoney('bank', valor)

				pPlayer.addAccountMoney('bank', valor)

				transferircarro(leilao.plate, maiorlicitacao.identificador)

				if isplayerOnline(maiorlicitacao.id) then
				TriggerClientEvent('chat:addMessage', maiorlicitacao.id, { args = {"^8AUKCe: ", 'Vyhral ste aukci ' .. maiorlicitacao.valor} })
				TriggerClientEvent('chat:addMessage', maiorlicitacao.id, { args = {"^8AUKCE: ", 'Muzete nyni odjet se svym vozem.'} })
				TriggerClientEvent('matif_leilaocarros:client:apagarcarro', maiorlicitacao.id)
				else
					apagarcarrop()
				end
				broadcastinscritos(maiorlicitacao.nome .. ' vyhral aukci s  ' .. math.floor(maiorlicitacao.valor) .. '$')
			else
				TriggerClientEvent('chat:addMessage', maiorlicitacao.id, { args = {"^8AUKCE: ", 'nemas dostatek penez v bance.'} })
			end
		else
			apagarcarrop()
		end

	else
		apagarcarrop()
		if isplayerOnline(leilao.id) then
			TriggerClientEvent('chat:addMessage', leilao.id, { args = {"^8AUKCE: ", 'nikdo neprihodil.'} })
		end
	end
	--TriggerClientEvent('matif_leilaocarros:client:apagarcarro', maiorlicitacao.id)
	maiorlicitacao = {}
	licitacoes = {}
	leilao = {}
	leilao.temporestante = 0
	leilao.running = false
	leilao.inscritos = {}
	TriggerClientEvent('matif_leilaocarros:client:forcesync', -1)
end

function broadcastinscritos(message)
	local players = ESX.GetPlayers()
	local found = false
	for i=1, #players, 1 do
		local identifierP = GetPlayerIdentifiers(players[i])[1]
		for k,v in pairs(leilao.inscritos) do
			if v.identifier == identifierP then
				TriggerClientEvent('chat:addMessage', players[i], { args = {"^8AUKCE: ", message} })
			end
		end
	end
end

function getBank()
	MySQL.Async.fetchScalar('SELECT bank FROM users WHERE identifier = @identifier', {
		['@identifier'] = leilao.identifier
	}, function(result)
		while result == nil do
			Citizen.Wait(200)
		end
		return result
	end)
end

function apagarcarrop()
	TriggerClientEvent('matif_leilaocarros:client:apagarcarrol', leilao.id)
end

RegisterServerEvent('matif_leilaocarros:sv:licitar')
AddEventHandler('matif_leilaocarros:sv:licitar', function()
	local _src = source
	local identifier = GetPlayerIdentifiers(source)[1]
	local nome = geticname(identifier)
	local xPlayer = ESX.GetPlayerFromId(_src)
	
	if leilao.running == true then
		if identifier ~= leilao.identifier then
			maiorlicitacao = {}
			local lid = {}
			local valorr = leilao.valor + math.floor(leilao.valor * 0.02)
			local banco = xPlayer.getBank()
			if banco >= valorr then
				leilao.valor = math.floor(valorr)
				table.insert(licitacoes, {id = _src, valor = valorr, nome = nome, identificador = identifier})
				maiorlicitacao.id = _src
				maiorlicitacao.valor = valorr
				maiorlicitacao.nome = nome
				maiorlicitacao.identificador = identifier
				lid.id = _src
				lid.valor = valorr
				lid.nome = nome
				lid.identificador = identifier
				mensageminscritos(lid)
				addinscritos(identifier)
				TriggerClientEvent('matif_leilaocarros:client:forcesync', -1)
				--matifp('Nova licitacao de ' .. nome .. ' - ' .. valorr)
			else
				TriggerClientEvent('chat:addMessage', _src, { args = {"^8AUKCIJA: ", 'Nemas dosta para.'} })
			end
		else
			TriggerClientEvent('chat:addMessage', _src, { args = {"^8AUKCIJA: ", 'Ne mozes sudjelovati u aukciji.'} })
		end
	else
		TriggerClientEvent('chat:addMessage', _src, { args = {"^8AUKCIJA: ", 'Zadna aukce se nyni nekona.'} })
	end	
end)

function isplayerOnline(id)
	local players = ESX.GetPlayers()
	local found = false
	for i=1, #players, 1 do
		if players[i] == id then
			found = true
		end
	end

	return found
end

function addinscritos(identifier)
	local found = false
	for k,v in pairs(leilao.inscritos) do
		if v.identifier == identifier then
			found = true
		end
	end

	if found == false then
		table.insert(leilao.inscritos, {identifier = identifier})
	end
end

function mensageminscritos(data)
	local players = ESX.GetPlayers()
	local found = false
	for i=1, #players, 1 do
		local identifierP = GetPlayerIdentifiers(players[i])[1]
		for k,v in pairs(leilao.inscritos) do
			if v.identifier == identifierP then
				TriggerClientEvent('chat:addMessage', players[i], { args = {"^8AUKCIJA: ", "Zadnja ponuda "..data.nome.." ("..data.valor.."$)"} })
			end
		end
	end
end

function geticname(identifier)
	local info = MySQL.Sync.fetchAll("SELECT * FROM users WHERE identifier = @identifier", {['@identifier'] = identifier})
	local nome
	
	for k,v in pairs(info) do
		nome = v.firstname .. ' ' .. v.lastname
	end

	return nome
end

RegisterServerEvent('matif_leilaocarros:sv:comecarleilao')
AddEventHandler('matif_leilaocarros:sv:comecarleilao', function(infoleilao)
	local _src = source
	local identifier = GetPlayerIdentifiers(source)[1]
	local nome = geticname(identifier)

	--print(infoleilao.vehicleName)

	if infoleilao ~= nil and leilao.running == false then
		leilao = infoleilao
		leilao.id = _src
		leilao.running = true
		leilao.identifier = identifier
		leilao.inscritos = {}
		table.insert(leilao.inscritos, {identifier = identifier})
		leilao.temporestante = auctiontime
		TriggerClientEvent('matif_leilaocarros:client:forcesync', -1)
		TriggerClientEvent('chat:addMessage', -1, { args = {"^8AUKCIJA: ", 'Nova aukcija: ' .. leilao.nome .. ' - Pocetna cijena: ' .. leilao.valor .. '$'} })
		PerformHttpRequest('https://discordapp.com/api/webhooks/692439800556290118/JzBs3MdfU1GfAFS1v4Eol7xzLZlKPwiZ8b_UGJwlIq6ZQfvNx08CGjC28Mp070cWyYjY', function(err, text, headers) end, 'POST', json.encode({ username = name,content = '@everyone  ' .. nome .. ' je krerirao aukciju zvana "' .. leilao.nome .. '"'}), { ['Content-Type'] = 'application/json' })
	else
		TriggerClientEvent('chat:addMessage', _src, { args = {"^8AUKCIJA: ", 'Nemas pravo.'} })
	end
end)

function transferircarro(matricula, transferer)

	local identifier = transferer

	MySQL.Async.execute('UPDATE owned_vehicles SET owner=@owner WHERE plate=@plate',
	{
		['@owner']   = identifier,
		['@plate']   = matricula
	},

	function (rowsChanged)
	end)

	if isplayerOnline(maiorlicitacao.id) then
		TriggerClientEvent('esx:showNotification', maiorlicitacao.id, 'Mate nove vozidlo s SPZ: ~g~' ..matricula)
	end
end

ESX.RegisterServerCallback('matif_leilaocarros:cb:tabelaleilao', function(source, cb)
	cb(leilao)
end)

ESX.RegisterServerCallback('matif_leilaocarros:cb:valor', function(source, cb)
	cb(leilao.valor + math.floor(leilao.valor * 0.05))
end)

ESX.RegisterServerCallback('matif_leilaocarros:cb:tabelalicitacoes', function(source, cb)
	cb(licitacoes)
end)

function table.empty(parsedTable)
	for _, _ in pairs(parsedTable) do
		return false
	end

	return true
end