power=0
temperature=20
STEP = .5
PIN_PLUS = 1
PIN_MINUS = 2
PIN_RELAY = 5
RELAY_ON = gpio.LOW
RELAY_OFF = gpio.HIGH
curr_relay = nil

function getCurrentTmp()
	return home_tmp['t1']
end

dofile("display.lua")

gpio.mode(PIN_RELAY,gpio.OUTPUT)

function updateRelay(status)
	if curr_relay ~= status then
		print("triggering relay "..status)
		curr_relay = status
		gpio.write(PIN_RELAY, curr_relay)
	end
end

if file.open("conf.lua") ~= nil then
	dofile("conf.lua")
end

function slice(tbl, first, last)
	local sliced = {}
	for i = first or 1, last or #tbl do
		sliced[#sliced+1] = tbl[i]
	end
	return sliced
end
	
function updateHomeTmp(key,value)
	home_tmp[key] = tonumber(string.format("%.1f", value))
	print("new tmp : "..key.."="..home_tmp[key])
	doRefreshDisplay()
end

-- listening mqtt (temperature='t', wifi credentials='w')
function eval_mqtt(client, topic, message)
	print("eval_mqtt")
	print(topic)
	print(message)
	if topic == "power" then
		power = message == "1" and 1 or 0
		print("power="..tostring(power))
	end
	if topic == "tx" then
		print("temperature: "..topic.." "..message)
		temperature = message
		onTempChange()
	end
	if topic == "wx" then
		print("credentials: "..topic.." "..message)
		local cre = file.open("credentials.lua","w")
		cre.write(message)
		cre.close()
	end
	if topic == "t1" then
		updateHomeTmp('t1',message)
	end
end
m = mqtt.Client("termostato", 120, "fhnmelxv", "GVyrRJ7jSVxg")
m:connect("farmer.cloudmqtt.com", 15778, false)
m:on("connect", function() m:subscribe({wx=0,tx=0,t1=0,power=0}, eval_mqtt) end)
m:on("message", function(client, topic, message) eval_mqtt(client, topic, message) end)
function updateConfig()
	local conf = file.open("conf.lua","w")
	conf.write("temperature, power = "..temperature..", "..power)
	conf.close()
end

function checkRelay()
	if power == 1 and getCurrentTmp() ~= nil and getCurrentTmp() < temperature then
		updateRelay(RELAY_ON)
	else
		updateRelay(RELAY_OFF)
	end
end
function onTempChange()
	doRefreshDisplay()
	updateConfig()
	
end

-- listening pins
-- Establish or clear a callback function to run on interrupt for a pin.
-- This function is not available if GPIO_INTERRUPT_ENABLE was undefined at compile time.
-- gpio.trig(pin, [type [, callback_function]])
--gpio.mode(PIN_PLUS,gpio.INT)
gpio.mode(PIN_PLUS,gpio.INPUT)
gpio.mode(PIN_MINUS,gpio.INPUT)
function triggerPIN_PLUS(level, when, eventcount)
     triggerPIN(level, when, eventcount, STEP)
end
function triggerPIN_MINUS(level, when, eventcount)
     triggerPIN(level, when, eventcount, -1 * STEP)
end
function triggerPIN(level, when, eventcount, value)
     temperature = temperature + value
	 onTempChange()
	 m:publish("t", temperature, 0, 0)
end
--gpio.trig(PIN_PLUS, "high", triggerPIN_PLUS)
--gpio.trig(PIN_MINUS, "high", triggerPIN_MINUS)
loop_tmr = tmr.create()
released = true
function loop()
	local pp = gpio.read(PIN_PLUS)
	local pm = gpio.read(PIN_MINUS)
	if pp == gpio.HIGH and released then
		print("plus triggered!!")
		triggerPIN_PLUS(0,0,0)
		released = false
	end
	if pm == gpio.HIGH and released then
		print("minus triggered!!")
		triggerPIN_MINUS(0,0,0)
		released = false
	end
	if pp == gpio.LOW and pm == gpio.LOW then
		released = true
	end
	checkRelay()
end
loop_tmr:register(200, tmr.ALARM_AUTO, loop) --ALARM_SEMI
loop_tmr:start()
