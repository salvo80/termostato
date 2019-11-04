temperature=""
STEP = .5
PIN_PLUS = 3
PIN_MINUS = 4

function onTempChange()
	doRefreshDisplay()
	updateConfig()
end
-- listening mqtt (temperature, wifi credentials)
function evalMQTT (client, topic, message)
	if topic=="t" then
		temperature=message
	end
	if topic=="w" then
		local cre = file.open("credentials.lua","w")
		cre.write(message)
		cre.close()
	end
end
mqtt:on(event, evalMQTT)

-- listening pins
-- Establish or clear a callback function to run on interrupt for a pin.
-- This function is not available if GPIO_INTERRUPT_ENABLE was undefined at compile time.
-- gpio.trig(pin, [type [, callback_function]])
gpio.mode(PIN_PLUS,gpio.INT,gpio.PULLUP)
gpio.mode(PIN_MINUS,gpio.INT,gpio.PULLUP)
function triggerPIN_PLUS(level, when, eventcount)
     triggerPIN(level, when, eventcount, STEP)
end
function triggerPIN_MINUS(level, when, eventcount)
     triggerPIN(level, when, eventcount, -1*STEP)
end
function triggerPIN(level, when, eventcount, value)
     temperature = temperature + value
end
gpio.trig(PIN_PLUS, "down", triggerPIN_PLUS)
gpio.trig(PIN_MINUS, "down", triggerPIN_MINUS)

-- refreshing display
function doRefreshDisplay()
	
end