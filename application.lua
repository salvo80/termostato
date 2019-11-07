temperature=25
STEP = .5
PIN_PLUS = 2
PIN_MINUS = 4

dofile("display.lua")

if file.open("conf.lua") ~= nil then
	dofile("conf.lua")
end

-- listening mqtt (temperature='t', wifi credentials='w')
function eval_mqtt(client, topic, message)
	print("eval_mqtt")
	print(topic)
	print(message)
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
end
m = mqtt.Client("termostato", 120, "fhnmelxv", "GVyrRJ7jSVxg")
m:connect("farmer.cloudmqtt.com", 15778, false)
m:on("connect", function() m:subscribe({wx=0,tx=0}, eval_mqtt) end)
m:on("message", function(client, topic, message) eval_mqtt(client, topic, message) end)
function updateConfig()
	local conf = file.open("conf.lua","w")
	conf.write("temperature="..temperature)
	conf.close()
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
--gpio.mode(PIN_MINUS,gpio.INT)
function triggerPIN_PLUS(level, when, eventcount)
     triggerPIN(level, when, eventcount, STEP)
end
function triggerPIN_MINUS(level, when, eventcount)
     triggerPIN(level, when, eventcount, -1*STEP)
end
function triggerPIN(level, when, eventcount, value)
     temperature = temperature + value
	 onTempChange()
	 m:publish("t", temperature, 0, 0)
end
--gpio.trig(PIN_PLUS, "high", triggerPIN_PLUS)
--gpio.trig(PIN_MINUS, "high", triggerPIN_MINUS)
loop_tmr = tmr.create()
function loop()
	if gpio.read(PIN_PLUS) == gpio.HIGH then
		print("triggered!!")
		triggerPIN_PLUS(0,0,0)
		loop_tmr:stop()
		tmr.create():alarm(900, tmr.ALARM_SINGLE, function() loop_tmr:start() end)
	end
end
loop_tmr:register(100, tmr.ALARM_AUTO, loop) --ALARM_SEMI
loop_tmr:start()
