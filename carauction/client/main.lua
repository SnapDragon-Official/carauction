ESX = nil
valor = nil
running = false
blipon = false
leilao = nil
got = false
tdisplay = 'Loading..'
temporestante = 0
licitacoes = {}

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
end)

Citizen.CreateThread(function()
	while true do 
		Citizen.Wait(100)
		if temporestante ~= 0 then
			temporestante = temporestante - 1000
			if temporestante > 60000 and temporestante < 120000 then
				tdisplay = math.floor((temporestante / 10000) / 6) .. ' minuta ' .. math.floor((temporestante / 1000) - (math.floor((temporestante / 10000) / 6)*60)) .. 'sekundi'
			elseif temporestante > 120000 then
				tdisplay = math.floor((temporestante / 10000) / 6) .. ' minuta ' .. math.floor((temporestante / 1000) - (math.floor((temporestante / 10000) / 6)*60)) .. 'sekundi'
			elseif temporestante == 0 then
				tdisplay = 'Wait..'
			else
				tdisplay = math.floor(temporestante / 1000) .. 'seconds'
			end
			Citizen.Wait(1000)
		end
	end	
end)

Citizen.CreateThread(function()
  while true do
	Citizen.Wait(10)
	local pedcoord = GetEntityCoords(GetPlayerPed(-1))
	local dist = GetDistanceBetweenCoords(pedcoord.x, pedcoord.y, pedcoord.z, 305.2864074707, -1162.4733886719, 29.291891098022, true)
	local dist2 = GetDistanceBetweenCoords(pedcoord.x, pedcoord.y, pedcoord.z, 313.90774536133, -1166.9274902344, 29.291858673096, true)
	
    if dist < 8 then
      DrawText3Ds(305.2864074707, -1162.4733886719, 29.291891098022, 'Pritisni [~g~E~s~] za aukciju vozila.', 0.4)
	end

	if got == false then
		TriggerEvent('matif_leilaocarros:client:forcesync')
		got = true
	end

	if dist2 < 20 and running == true then
		DrawText3DsB(313.90774536133, -1166.9274902344, 31.851858673096, '~b~Naziv aukcije: ~s~' .. leilao.nome, 0.4)
		DrawText3DsB(313.90774536133, -1166.9274902344, 31.501858673096, '~b~Preostalo vrijeme: ~s~' .. tdisplay, 0.4)
		DrawText3DsB(313.90774536133, -1166.9274902344, 31.151858673096, '~b~Pocetna cijena: ~s~' .. leilao.valor, 0.4)
	end
	
	if dist < 3 then
		if IsControlJustPressed(0, 38) then
			abrirmenu()
		end
	end

	if dist2 < 20 and dist > 3 and running == true then
		if blipon == false then
			exports['mythic_notify']:PersistentAlert('START', '1','success','Pritisni Y da licitiras')
			blipon = true
		end
		--ESX.ShowHelpNotification('Clica [~g~Y~s~] para licitares!')
		if IsControlJustPressed(0, 246) then
			if temporestante > 0 then
				TriggerServerEvent('matif_leilaocarros:sv:licitar')
			end
		end
	else
		if blipon == true then
			exports['mythic_notify']:PersistentAlert('END', '1')
			blipon = false
		end
	end

	
  end
end)

function abrirmenu()
	local elements = {}
	if running == false then
		table.insert(elements, {label = 'Zadnja aukcija', value = 'ne'})
		table.insert(elements, {label = 'Izaberi auto za aukciju', value = 'comecarleilao'})
	else
		table.insert(elements, {label = 'Polozka aukce: ' .. leilao.nome, value = 'ne2'})
		table.insert(elements, {label = 'Posledni prihod', value = 'ulicitacoes'})
	end


	ESX.UI.Menu.Open(

		'default', GetCurrentResourceName(), 'matif_leilaocarros',
		{
		  title    = 'Aukcni barak',
		  align    = 'bottom-right',
		  elements = elements
		},

		function(data, menu)
			--if data.current.value == 'licitar' then
				--TriggerEvent('matif_leilaocarros:client:licitar')
			if data.current.value == 'comecarleilao' then
				--print('a')
				menu.close()
				abrirmenucomecar()
			elseif data.current.value == 'ulicitacoes' then
				abrirmenulicitacoes()
			end
		end,

	  	function(data, menu)
			menu.close()
	  	end
	)
end

function abrirmenulicitacoes()
	local elements = {}

	if not table.empty(licitacoes) then
		for k,v in pairs(licitacoes) do
			local lb = v.nome .. ' - <span style="color:limegreen;">' .. v.valor .. '$</span>'
			--print(lb)
			table.insert(elements, {label = lb, preco = v.valor, value = 'ez'})
		end
	else
		table.insert(elements, {label = 'Nikdo neprihodil!', preco = 1, value = 'ez'})
	end

	Citizen.Wait(100)

	--table.sort(elements)
	
	for k,v in pairs(elements) do
		--print(v.label)
	end

	ESX.UI.Menu.Open(

		'default', GetCurrentResourceName(), 'matif_leilaocarross',
		{
		  title    = 'Posledni castka',
		  align    = 'bottom-right',
		  elements = elements
		},

		function(data, menu)
			if data.current.value == 'ez' then
				--print('teste sucess')
			end
		end,

	  function(data, menu)
		menu.close()
		--abrirmenu()
	  end
	)
end

function abrirmenucomecar()
	local elements = {}
	local vehiclePropsList = {}

	ESX.TriggerServerCallback('matif_leilaocarros:cb:getcarros', function(vehicles)
		if not table.empty(vehicles) then
			for k,v in ipairs(vehicles) do
				local vehicleProps = json.decode(v.vehicle)
				vehiclePropsList[vehicleProps.plate] = vehicleProps
				local vehicleHash = vehicleProps.model
				local vehicleName
				vehicleName = GetDisplayNameFromVehicleModel(vehicleHash)
				table.insert(elements, {label = vehicleName, plate = vehicleProps.plate, props = vehicleProps})
			end
		else
			table.insert(elements, {label = "Nevlastni zadne vozidlo."})
		end
	end)

	Citizen.Wait(500)

	ESX.UI.Menu.Open(

		'default', GetCurrentResourceName(), 'matif_leilaocarros',
		{
		  title    = 'Vyber auto',
		  align    = 'bottom-right',
		  elements = elements
		},

		function(data, menu)
			local vehicleProps = vehiclePropsList[data.current.plate]
			if data.current.plate ~= nil then
				ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'escolhernome', {
					title = 'Aukcni Jmeno'
				}, function(data2, menu2)
					local nome = data2.value
					if nome ~= nil then
						menu2.close()
						ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'precoinical', {
							title = 'Zacit prihazovat'
						}, function(dataa, menuu)
							local preco = dataa.value
							if tonumber(preco) ~= nil then
								menuu.close()
								ESX.UI.Menu.CloseAll()
								comecarleilaoo(data.current.label, data.current.plate, nome, preco, data.current.props)
							end
						end, function(dataa, menuu)
							menuu.close()
						end)
					else
						--print('nao pode estar vazio')
					end
				end, function(data2, menu2)
					menu2.close()
				end)
			end
		end,

	  	function(data, menu)
			menu.close()
	  	end
	)

end

function comecarleilaoo(vehicleName, plate, nome, preco, props)
	--print(vehicleName)
	tabcomeco = {}

	tabcomeco.vehicleName = vehicleName 
	tabcomeco.plate = plate
	tabcomeco.nome = nome
	tabcomeco.valor = preco
	tabcomeco.props = props

	TriggerServerEvent('matif_leilaocarros:sv:comecarleilao', tabcomeco)

	ESX.Game.SpawnVehicle(props.model, { x = 313.61602783203, y = -1163.8139648438, z = 28.341889190674 + 1}, 306.6, function(callback_vehicle)
		ESX.Game.SetVehicleProperties(callback_vehicle, props)
	end)

	Citizen.Wait(1000)

	local vehicle = GetClosestVehicle(313.61602783203, -1163.8139648438, 28.341889190674, 2.0, 0, 71)
	--print('------')
	--print(vehicle)
	FreezeEntityPosition(vehicle, true)
	SetEntityInvincible(vehicle, true)
end


RegisterNetEvent('matif_leilaocarros:client:apagarcarro')
AddEventHandler('matif_leilaocarros:client:apagarcarro', function()

	local vehicle = GetClosestVehicle(313.61602783203, -1163.8139648438, 28.341889190674, 2.0, 0, 71)
	FreezeEntityPosition(vehicle, false)
	SetEntityInvincible(vehicle, false)
end)

RegisterNetEvent('matif_leilaocarros:client:apagarcarrol')
AddEventHandler('matif_leilaocarros:client:apagarcarrol', function()

	local vehicle = GetClosestVehicle(313.61602783203, -1163.8139648438, 28.341889190674, 2.0, 0, 71)
	
	DeleteVehicle(vehicle)
end)

RegisterNetEvent('matif_leilaocarros:client:forcesync')
AddEventHandler('matif_leilaocarros:client:forcesync', function()
	--print('Syncing Forcefully')
	ESX.TriggerServerCallback('matif_leilaocarros:cb:tabelaleilao', function(result)
		leilao = result
		if result.running == true then
			if temporestante == 0 then
				temporestante = leilao.temporestante
			end
			running = true
		else
			running = false
		end
	end)
	ESX.TriggerServerCallback('matif_leilaocarros:cb:tabelalicitacoes', function(resultt)
		if not table.empty(resultt) then
			for k,v in ipairs(resultt) do
				licitacoes = resultt
			end
		end
	end)
end)

function table.empty(parsedTable)
	for _, _ in pairs(parsedTable) do
		return false
	end

	return true
end

function DrawText3Ds(x,y,z, text)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
  
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    DrawText(_x,_y)
    local factor = (string.len(text)) / 370
    DrawRect(_x,_y+0.0125, 0.015+ factor, 0, 0, 0, 0.0)
end

function DrawText3DsB(x,y,z, text)
	local onScreen,_x,_y=World3dToScreen2d(x,y,z)
	local px,py,pz=table.unpack(GetGameplayCamCoords())
  
	SetTextScale(0.6, 0.6)
	SetTextFont(4)
	SetTextProportional(1)
	SetTextColour(255, 255, 255, 215)
	SetTextEntry("STRING")
	SetTextCentre(true)
	AddTextComponentString(text)
	DrawText(_x,_y)
	local factor = (string.len(text)) / 370
	DrawRect(_x,_y+0.0125, 0.015+ factor, 0, 0, 0, 0.0)
end

