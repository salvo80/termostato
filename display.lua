DISPLAY_sda = 4 -- GPIO2 D4
DISPLAY_scl = 3 -- GPIO0 D3

function init_i2c_display()
    local sla = 0x3c
    i2c.setup(0, DISPLAY_sda, DISPLAY_scl, i2c.SLOW)
    disp = u8g2.ssd1306_i2c_128x64_noname(0, sla)
end

init_i2c_display()

function u8g2_prepare()
  --disp:setFont(u8g2.font_6x10_tf)
  disp:setFont(u8g2.font_inr16_mf)
  disp:setFontRefHeightExtendedText()
  disp:setDrawColor(1)
  disp:setFontPosTop()
  disp:setFontDirection(0)
end

function draw()
  u8g2_prepare()
  
  --disp:drawStr( 0, 0, "Scegli la temperatura")
  --disp:setFont(u8g2.font_logisoso16_tr)
  
  print('display current tmp: '..(getCurrentTmp()~=nil and getCurrentTmp() or 'nil'))
  disp:drawStr( 10, 40, tostring(temperature)..(getCurrentTmp()~=nil and ' ('..tostring(getCurrentTmp())..')' or '') )
  
end

function doRefreshDisplay()
  disp:clearBuffer()
  draw()
  disp:sendBuffer()
end

