local M, module = {}, ...

function M.update() 
    i2c.setup(0, 2, 1, i2c.SLOW)
    i2c.start(0)
    i2c.address(0, 0x15, i2c.TRANSMITTER)
    i2c.write(0, 0x00)
    i2c.write(0, 0x05)
    i2c.stop(0)
end
function M.colorAll(r,g,b)
    i2c.setup(0, 2, 1, i2c.SLOW)
    i2c.start(0)
    i2c.address(0, 0x15, i2c.TRANSMITTER)
    i2c.write(0, 0x00)
    i2c.write(0, 0x01)
    i2c.write(0,r)
    i2c.write(0,g)
    i2c.write(0,b)
    i2c.stop(0)
    M.update()
end
function M.brightness(bright)
    i2c.setup(0, 2, 1, i2c.SLOW)
    i2c.start(0)
    i2c.address(0, 0x15, i2c.TRANSMITTER)
    i2c.write(0, 0x00)
    i2c.write(0, 0x03)
    i2c.write(0,bright)
    i2c.stop(0)
    M.update()
end

function M.color(which, r, g, b)
    i2c.setup(0, 2, 1, i2c.SLOW)
    i2c.start(0)
    i2c.address(0, 0x15, i2c.TRANSMITTER)
    i2c.write(0, 0x00)
    i2c.write(0, 0x00)
    i2c.write(0,which)
    i2c.write(0,r)
    i2c.write(0,g)
    i2c.write(0,b)
    i2c.stop(0)
    M.update()
end
return M 