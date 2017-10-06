

--APDS 9960 Firmware Under Development

--[[
    The concept of this module is different.
    APDS do not return which direction , it only return the raw data 
    and the MCU must calculate to come up with the result
    
    Below is raw data processing. Not completed
    
    Started on 10/9/17
    --add pseudo code
    --start porting
    --based on Sparkfun library
    ++13/09/17
        - Gesture class function ported to lua
        --having problem with bit operation in lua
        --hard-code all the variable and define
        -- add readGesture , need I2C source code , 
        -- function return 2 parameter need to be supported.
    This code is absolutely not optimised by any means. Follow us on  "getblocky.com" for more details.
]]--

data_U = {}
data_L = {}
data_D = {}
data_R = {}
function wireReadDataBlock(reg, length)
	print(length)
	print(reg)
	wireWriteByte(reg)
	i2c.start(0)
	i2c.address(0, 0x39, i2c.RECEIVER)
    data = i2c.read(0,length)
	for i = 1 , 10 do
		print(string.byte(data[i]))
	end
    i2c.stop(0)
	
	return data, length
end
function processGestureData()
--define variable
	--print("Process Gesture")
    u_first = 0
    d_first = 0
    l_first = 0
    r_first = 0
    u_last = 0
    d_last = 0
    l_last = 0
    r_last = 0
    ud_ratio_first=0
    lr_ratio_first=0
    ud_ratio_last=0
    lr_ratio_last=0
    ud_delta=0
    lr_delta=0
    i=0
    
    if total_gesture >=4 and total_gesture <= 32 then
        --find the first data
        for i = 1 , total_gesture do
            if data_U[i] > 10 and data_L[i] > 10
                and data_D[i] > 10 and data_R[i] > 10 then
                    u_first = data_U[i]
                    d_first = data_D[i]
                    l_first = data_L[i]
                    r_first = data_R[i]
                    break
            end
        end
		
        --no zero data allowed degrader
        --find the last data
		if u_first == 0 or d_first == 0 or l_first == 0 or r_first == 0 then 
			print("Bad First")
		end
		
        for i = total_gesture -1 , 1 , -1  do
            if data_U[i] > 10 and data_L[i] > 10
                and data_D[i] > 10 and data_R[i] > 10 then
                    u_last = data_U[i]
                    d_last = data_D[i]
                    l_last = data_L[i]
                    r_last = data_R[i]
                    break
					
            end
        end
    else 
		--print("Process Fail")
		return false 
	end
    
    --calculate the first vs last ratio of up down left right
	
    ud_ratio_first = ((u_first - d_first) * 100) 
	lr_ratio_first = ((l_first - r_first) * 100) 
    ud_ratio_last = ((u_last - d_last) * 100) 
    lr_ratio_last = ((l_last - r_last) * 100) 
    
	if u_first + d_first ~= 0 then  ud_ratio_first = ud_ratio_first  / (u_first + d_first) end
	if l_first + r_first ~= 0 then  lr_ratio_first = lr_ratio_first  / (l_first + r_first) end
	if u_last + d_last ~= 0 then  ud_ratio_last = ud_ratio_last  / (u_last + d_last) end
	if l_last + r_last ~= 0 then  lr_ratio_last = lr_ratio_last  / (l_last + r_last) end
	

    --determine the different between the first and the last ratio
    ud_delta = ud_ratio_last - ud_ratio_first
    lr_delta = lr_ratio_last - lr_ratio_first
    
    -- Accumulate the UD and LR delta values */
    gesture_ud_delta_ = ud_delta + gesture_ud_delta_
    gesture_lr_delta_ = lr_delta + gesture_lr_delta_
    -- Determine U/D gesture */
    if gesture_ud_delta_ >= 50 then --GESTURE_SENSITIVITY_1
        gesture_ud_count_ = 1
    elseif gesture_ud_delta_ <= -50 then --GESTURE_SENSITIVITY_1
        gesture_ud_count_ = -1
    else 
        gesture_ud_count_ = 0
    end
    
    -- Determine L/R gesture */
    if gesture_lr_delta_ >= 50 then gesture_lr_count_ = 1--GESTURE_SENSITIVITY_1
    elseif gesture_lr_delta_ <= -50 then gesture_lr_count_ = -1--GESTURE_SENSITIVITY_1
    else gesture_lr_count_ = 0
    end
    -- Determine Near/Far gesture */
    if gesture_ud_count_ == 0 and gesture_lr_count_ == 0 then
        if math.abs(ud_delta) < 20 and  math.abs(lr_delta) < 20 then --GESTURE_SENSITIVITY_2
            if ud_delta == 0 and lr_delta == 0 then gesture_near_count_ =gesture_near_count_ + 1
            elseif ud_delta ~= 0 or lr_delta ~= 0 then gesture_far_count_ = gesture_far_count_ +1
            else 
            end
            
            if gesture_near_count_ >= 10 and gesture_far_count_ >= 2 then
                if ud_delta == 0 and lr_delta == 0 then gesture_state_ = NEAR_STATE 
				print("Near")
                elseif ud_delta ~= 0 and lr_delta ~= 0 then     gesture_state_ = FAR_STATE
				print("Far")
                else
                end
                return true
            end
        end
    else 
        if math.abs(ud_delta) < 20 and math.abs(lr_delta) < 20 then
            if ud_delta == 0 and delta == 0 then gesture_near_count_ = gesture_near_count_ +1
            end
            if gesture_near_count_ >= 10 then
                gesture_ud_count_ = 0
                gesture_lr_count_ = 0
                gesture_ud_delta_ = 0
                gesture_lr_delta_ = 0
            end
        end
    end
	return false
end
function decodeGesture()
	--print("Decode Gesture")
    if gesture_state_ == 1 then 
        gesture_motion_ = 5
		print("Near State")
        return true
    elseif gesture_state_ == 2 then 
        gesture_motion_ = 6
		print("Far State")
        return true
    else end
    --determite swipe direction
    if gesture_ud_count_ == -1 and gesture_lr_count_ == 0 then
        gesture_motion_ = 3
		print("Up State")
    elseif gesture_ud_count_ == 1 and gesture_lr_count_ == 0 then
        gesture_motion_ = DIR_DOWN
		print("Down State")
    elseif gesture_ud_count_ == 0 and gesture_lr_count_ == 1 then
        gesture_motion_ = 2
		print("Right State")
    elseif gesture_ud_count_ == 0 and gesture_lr_count_ == -1 then
        gesture_motion_ = 1
		print("Left State")
    elseif gesture_ud_count_ == -1 and gesture_lr_count_ == 1 then
        if math.abs(gesture_ud_delta_) > math.abs(gesture_lr_delta_) then 
            gesture_motion_ = 3
			print("Up State")
        else
            gesture_motion_ = 2
			print("Right State")
        end
    elseif gesture_ud_count_ == 1 and gesture_lr_count_ == -1 then
        if math.abs(gesture_ud_delta_) > math.abs(gesture_lr_delta_) then 
            gesture_motion_ = 4
			print("Down State")
        else
            gesture_motion_ = 1
			print("Left State")
        end
    elseif gesture_ud_count_ == -1 and gesture_lr_count_ == -1 then
        if math.abs(gesture_ud_delta_) > math.abs(gesture_lr_delta_) then 
            gesture_motion_ = DIR_UP
			print("Up State")
        else
            gesture_motion_ = 1
			print("Left State")
        end
    elseif gesture_ud_count_ == 1 and gesture_lr_count_ == 1 then
        if math.abs(gesture_ud_delta_) > math.abs(gesture_lr_delta_) then 
            gesture_motion_ = 4
			print("Down State")
        else
            gesture_motion_ = 2
			print("Right State")
        end
    else 
        return false
    end
    return true
end



function readGesture()
	fifo_level = 0 
	bytes_read = 0 
	fifo_data = {} 
	gstatus = 0 
	motion = 0 
	i = 0 
	
	if isGestureAvailable() == false then 
		print("EnA")
		return 0 
	end
	if bit.isset(getMode(), 0 ) == false or bit.isset(getMode(),6) == false then 
		print("W")
		return 0 
	end
	
	print("G")
	
	while true do
		tmr.delay(3000)
		gstatus = wireReadDataByte(0xAF) --APDS9960_GSTATUS
		if bit.isset(gstatus,0) == true then 
			--print("GREQ")
			fifo_level = wireReadDataByte(0xAE) --APDS9960_GFLVL
			--print("Available")
			--print(fifo_level)
			if fifo_level > 0 then 
				--wireReadDataBlock
				wireWriteByte(0xFC)
				tmr.delay(30)
				i2c.start(0)
				i2c.address(0, 0x39, i2c.RECEIVER)
				str = i2c.read(0,fifo_level*4)
				i2c.stop(0)
				
				b = {}
				str:gsub(".",function(c) table.insert(b,c) end)
				index = 0 
				time = fifo_level*4
				total_gesture = 0 
				for i = 1 , time, 4 do 
					data_U[index] = string.byte(b[i+0])
					data_D[index] = string.byte(b[i+1])
					data_L[index] = string.byte(b[i+2])
					data_R[index] = string.byte(b[i+3])
					index = index + 1
					total_gesture = total_gesture + 1
				end
				
				if processGestureData() == true then 
					
					decodeGesture()
				end
				
				index = 0 
				total_gesture = 0 
				
			end
			
		else 
			tmr.delay(30000)
			decodeGesture()
			motion = gesture_motion_
			resetGestureParameter()
			
			--return motion 
		end
		
	end 
	
end

function handleGesture()
    if isGestureAvailable() == true then
        local gesture  = readGesture()
        print("Get")
        print(gesture)
	else 
		print("NGy")
    end
end



function now()
    --[[
        interrupr -> handleGesture -? available -> readGesture -> re interrupt
         
    ]]--
    end
function isGestureAvailable()
    i2c.setup(0, 2, 1, i2c.SLOW)
    i2c.start(0)
    i2c.address(0, 0x39, i2c.TRANSMITTER)
    i2c.write(0, 0xAF)
    i2c.stop(0)
    i2c.start(0)
    i2c.address(0,0x39, i2c.RECEIVER)
    msg = string.byte(i2c.read(0,1))
    --mask the last bit of this byte
    --if 1 then there is something , 0 is not
    if bit.bit(msg,7) == 1 then 
		return true
    else return false 
	end
end

function enableGestureSensor()

    --resetGestureParameter()
    wireWriteDataByte(0x83, 0xFF) 
    wireWriteDataByte(0x8E, 0x89)
    
    setLEDBoost(3)
    setGestureIntEnable(1)
    setGestureMode(1)
    
    setMode(0, 1)
    setMode(3, 1)
    setMode(2, 1)
    setMode(6, 1)
    
    return true
end
function setGestureMode(mode)
	local val = wireReadDataByte(0xAB)--APDS9960_GCONF4
	if mode == 1 then bit.set(val,0)
	else bit.clear(val,0)
	end
	wireWriteDataByte(0xAB,val)
end
function resetGestureParameter()
    index = 0
    total_gesture = 0 
    gesture_ud_delta_ = 0 
    gesture_lr_delta_ = 0 
    gesture_ud_count_ = 0
    gesture_lr_count_ = 0 
    gesture_near_count_ = 0 
    gesture_far_count_ = 0 
    gesture_state_ = 0 
    gesture_motion_ = 0
end
function wireWriteDataByte(reg,val)
    i2c.start(0)
    local error = i2c.address(0, 0x39, i2c.TRANSMITTER)
    i2c.write(0, reg)
    i2c.write(0, val)
    i2c.stop(0)
    return error
end
function wireWriteByte(val)
    i2c.start(0)
    local error = i2c.address(0, 0x39, i2c.TRANSMITTER)
    i2c.write(0,val)
    i2c.stop(0)
    return error
end
function wireReadDataByte(reg)
    i2c.start(0)
    local error = i2c.address(0, 0x39, i2c.TRANSMITTER)
   -- if error == true then print("SuccessWrite") end
    i2c.write(0,reg)
    i2c.stop(0)
    i2c.start(0)
    error = i2c.address(0, 0x39, i2c.RECEIVER)
 --   if error == true then print("SuccessRead") end
    c = i2c.read(0,1)
    i2c.stop(0)
    return string.byte(c) 
end
function getMode()
local enable_value = 0 
enable_value = wireReadDataByte(0x80)
return enable_value
end
function setMode(mode,enable)
    reg_val=0
    reg_val = getMode()
    if reg_val == 0xFF then   return false end
    
    if mode >= 0 and mode <= 6 then
        if enable> 0 then
            reg_val = bit.set(reg_val,mode)
        else 
            reg_val = bit.clear(reg_val,mode)
        end
    elseif mode == 7 then
        if enable > 0 then
            reg_val = 0x7F
        else
            reg_val = 0x00
        end
    end
        
   
    wireWriteDataByte(0x80, reg_val) 
      
    return true;
end
function setLEDDrive(drive)
	local val = wireReadDataByte(0x8F)--APDS9960_CONTROL
	if drive == 0 then 
		bit.clear(val,7)
		bit.clear(val,6)
	elseif drive == 1 then
		bit.clear(val,7)
		bit.set(val,6)
	elseif drive ==3 then
		bit.clear(val,6)
		bit.set(val,7)
	elseif drive ==4 then
		bit.set(val,6)
		bit.set(val,7)
	else 
	end
	wireWriteDataByte(0x8F,val)
end
function getProximityGain()
	local val = wireReadDataByte(0x8F)--APDS9960_CONTROL
	val = bit.band(bit.rshift(val,2) , 3)
	return val
end
function setProximityGain(drive)
	local val = wireReadDataByte(0x8F)--APDS9960_CONTROL
	if drive == 0 then 
		bit.clear(val,3)
		bit.clear(val,2)
	elseif drive == 1 then
		bit.clear(val,3)
		bit.set(val,2)
	elseif drive ==3 then
		bit.clear(val,3)
		bit.set(val,2)
	elseif drive ==4 then
		bit.set(val,3)
		bit.set(val,2)
	else 
	end
	wireWriteDataByte(0x8F,val)
end
function getAmbientLightGain()
	local val = wireReadDataByte(0x8F)--APDS9960_CONTROL
	val = bit.band(val,3)
	return val
end
function setAmbientLightGain(drive)
	local val = wireReadDataByte(0x8F)--APDS9960_CONTROL
	if drive == 0 then 
		bit.clear(val,1)
		bit.clear(val,0)
	elseif drive == 1 then
		bit.clear(val,1)
		bit.set(val,0)
	elseif drive ==3 then
		bit.clear(val,1)
		bit.set(val,0)
	elseif drive ==4 then
		bit.set(val,1)
		bit.set(val,0)
	else 
	end
	wireWriteDataByte(0x8F,val)

end
function getLEDBoost()
	local val = wireReadDataByte(0x90)--APDS9960_CONFIG2
	val = bit.band(bit.rshift(val,4),3)
	return val
end
function setLEDBoost()
	local val = wireReadDataByte(0x90)--APDS9960_CONFIG2
	if drive == 0 then 
		bit.clear(val,5)
		bit.clear(val,4)
	elseif drive == 1 then
		bit.clear(val,5)
		bit.set(val,4)
	elseif drive ==3 then
		bit.clear(val,5)
		bit.set(val,4)
	elseif drive ==4 then
		bit.set(val,5)
		bit.set(val,4)
	else 
	end
	wireWriteDataByte(0x90,val)
end
function getProxGainCompEnable()
	local val = wireReadDataByte(0x9F)--APDS9960_CONFIG3
	val = bit.bit(val,5)
	return val
end
function setProxGainCompEnable(enable)
	local val = wireReadDataByte(0x9F)--APDS9960_CONFIG3
	if enable == 1 then bit.set(val,5)
	else bit.clear(val,5)
	end
	wireWriteDataByte(0x9F,val)
end
function getProxPhotoMask()
	local val = wireReadDataByte(0x9F)--APDS9960_CONFIG3
	val = bit.band(val,15)
	return val
end
function setProxPhotoMask(mask)
	local val = wireReadDataByte(0x9F)--APDS9960_CONFIG3
	mask = bit.band(mask,15)
	val = bit.band(val,0xF0)
	val = bit.bor(val,mask)
	wireWriteDataByte(0x9F,val)
end
function getGestureEnterThresh()
	local val = wireReadDataByte(0xA0) --APDS9960_GPENTH
	return val
end
function setGestureEnterThresh(threshold)
	wireWriteDataByte(0xA0,threshold) --APDS9960_GPENTH
end
function getGestureExitThresh()
	local val = wireReadDataByte(0xA1) --APDS9960_GEXTH
	return val
end
function setGestureExitThresh(threshold)
	wireWriteDataByte(0xA1,threshold) --APDS9960_GEXTH
end
function getGestureGain()
	local val = wireReadDataByte(0xA3)--APDS9960_GCONF2
	val = bit.band(bit.rshift(val,5) ,3)
	return val
end
function setGestureGain(gain)
	local val = wireReadDataByte(0xA3)--APDS9960_GCONF2
	gain = bit.band(gain,3)
	gain = bit.lshift(gain,5)
	val = bit.band(val,0x9F)
	val = bit.bor(val,gain)
	wireWriteDataByte(0xA3, val) 
end
function getGestureLEDDrive()
	local val = wireReadDataByte(0xA3)--APDS9960_GCONF2
	val = bit.band(bit.rshift(val,3),3)
	return val
end
function setGestureLEDDrive(drive)
	local val = wireReadDataByte(0xA3)--APDS9960_GCONF2
	drive = bit.lshift(bit.band(drive,3),3)
	val = bit.bor(bit.band(val,0x9F),drive)
	wireWriteDataByte(0xA3, val) 
end
function getGestureWaitTime()
	local val = wireReadDataByte(0xA3)--APDS9960_GCONF2
	val = bit.band(val,0x07)
	return val
end
function setGestureWaitTime(time)
	local val = wireReadDataByte(0xA3)--APDS9960_GCONF2
	time = bit.band(time,0x07)
	val = bit.bor(time,bit.band(val,0xF8))
	wireWriteDataByte(0xA3, val) 
end
function setProxIntLowThresh()
end
function setProxIntHighThresh(threshold)
	wireWriteDataByte(0x8B,threshold) --APDS9960_PIHT
end
function setLightIntLowThreshold(threshold)
	wireWriteDataByte(0x84 , threshold % 256 )--APDS9960_AILTL
	wireWriteDataByte(0x85 , math.floor(threshold/256))--APDS9960_AILTH
end
function setLightIntHighThreshold(threshold)
	wireWriteDataByte(0x86 , threshold % 256 )--APDS9960_AIHTL
	wireWriteDataByte(0x87 , math.floor(threshold/256))--APDS9960_AIHTH
end
function setGestureIntEnable(enable)
	local val = wireReadDataByte(0xAB)--APDS9960_GCONF4
	if enable == 1 then val = bit.set(val,1)
	else val = bit.clear(val,1)
	end
	wireWriteDataByte(0xAB, val) 
end




function init()
    i2c.setup(0, 2, 1, i2c.SLOW)
    local id = wireReadDataByte(0x92)
    if id == 0xAB or id == 0x9C then
		print("Done")
        setMode(7,0)--setAll OFF
        wireWriteDataByte(0x81,219)--APDS9960_ATIME
        wireWriteDataByte(0x83,246)--APDS9960_WTIME
        wireWriteDataByte(0x8E,0x87)--APDS9960_PPULSE
        wireWriteDataByte(0x9D,0)--APDS9960_POFFSET_UR
        wireWriteDataByte(0x9E,0)--APDS9960_POFFSET_DL
        wireWriteDataByte(0x8D,0x60)--APDS9960_CONFIG1
        setLEDDrive(0)
        setProximityGain(2) --PGAIN_4X
        setAmbientLightGain(1) --AGAIN_4X
		setProxIntLowThresh(0)
        setProxIntHighThresh(50)
        setLightIntLowThreshold(0xFFFF)
        setLightIntHighThreshold(0)
        wireWriteDataByte(0x8C,0x11)--APDS9960_PERS
        wireWriteDataByte(0x90,0x01)--APDS9960_CONFIG2
        wireWriteDataByte(0x9F,0x00)--APDS9960_CONFIG3
	--set value for gesture sensor
        setGestureEnterThresh(40)
        setGestureExitThresh(30)
        wireWriteDataByte(0xA2,0x40)--APDS9960_GCONF1
		setGestureGain(3)--GGAIN_4X
		setGestureLEDDrive(0)--LED_DRIVE_100MA
		setGestureWaitTime(1)--GWTIME_2_8MS
        wireWriteDataByte(0xA3,0x41)--APDS9960_GOFFSET_U
        wireWriteDataByte(0x8C,0x11)--APDS9960_GOFFSET_D
        wireWriteDataByte(0x90,0x01)--APDS9960_GOFFSET_L
        wireWriteDataByte(0x9F,0x00)--APDS9960_GOFFSET_R
		wireWriteDataByte(0xA6,0xC9)--APDS9960_GPULSE
		wireWriteDataByte(0xAA,0x00)--APDS9960_GCONF3
		setGestureIntEnable(1) --disable
        return true
    else 
        print("Wrong address")
        return false
    end
end



function main()

    if init() == true then print("Startup Completed")
    else print("Wow, try one more times")
    end
    
    if enableGestureSensor(true) == true then print("Enabled Gesture")
    else print("Problem enabling")
    end
    
    
        handleGesture()
        tmr.delay(100000)       
    
end

main()





