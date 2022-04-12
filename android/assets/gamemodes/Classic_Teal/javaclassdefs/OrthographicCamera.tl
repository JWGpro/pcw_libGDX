local record Vector3
    x: number
    y: number
    z: number  -- Not relevant for 2D cameras
end

local record OrthographicCamera
    position: Vector3
    zoom: number
    viewportWidth: number
    viewportHeight: number

    translate: function(OrthographicCamera, number, number)
end

return OrthographicCamera