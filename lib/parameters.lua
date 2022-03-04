local parameters = {}

function parameters.init()
  params:add{
    type="option", id = "x_input", name = "x input", options={"first","second","third"},default = 1,
    action=function(x) 
      lorenz:reset()
    end
  }
  params:add{
    type="option", id = "y_input", name = "y input", options={"first","second","third"},default = 2,
    action=function(x) 
      lorenz:reset()
    end
  }

  params:add{
    type="number", id = "x_offset", name = "x offset",min=-64, max=64, default = 0,
    action=function(x) 
      lorenz:reset()
    end
  }
  params:add{
    type="number", id = "y_offset", name = "y offset",min=-32, max=32, default = 0,
    action=function(x) 
      lorenz:reset()
    end
  }

  params:add{
    type="number", id = "xy_offset", name = "xy offset",min=-64, max=64, default = 0,
    action=function(x) 
      params:set("x_offset",x)
      params:set("y_offset",x)
      lorenz:reset()
    end
  }

  params:add{
    type="taper", id = "x_scale", name = "x scale",min=0.01, max=10, default = 1,
    action=function(x) 
      lorenz:reset()
    end
  }
  
  params:add{
    type="taper", id = "y_scale", name = "y scale",min=0.01, max=10, default = 1,
    action=function(x) 
      lorenz:reset()
    end
  }

  params:add{
    type="taper", id = "xy_scale", name = "xy scale",min=0.01, max=10, default = 1,
    action=function(x) 
      params:set("x_scale",x)
      params:set("y_scale",x)
      lorenz:reset()
    end
  }


  params:add{
    type="taper", id = "origin1", name = "origin1",min=0.000, max=20, default = 0.01,
    action=function(x) 
      lorenz.origin[1]=x
      lorenz:reset()
    end
  }
  
  params:add{
    type="taper", id = "origin2", name = "origin2",min=0.000, max=20, default = 0.5,
    action=function(x) 
      lorenz.origin[2]=x
      lorenz:reset()
    end
  }

  params:add{
    type="taper", id = "origin3", name = "origin3",min=0.000, max=20, default = 0.0,
    action=function(x) 
      lorenz.origin[3]=x
      lorenz:reset()
    end
  }

  params:add{
    type="taper", id = "sigma", name = "sigma",min=0.001, max=10, default = 2.333,
    action=function(x) 
      lorenz.dt=x
      lorenz:reset()
    end
  }

  params:add{
    type="number", id = "rho", name = "rho",min=1, max=50, default = 28,
    action=function(x) 
      lorenz.rho=x
      lorenz:reset()
    end
  }

  params:add{
    type="taper", id = "beta", name = "beta",min=0.01, max=2, default = 4/3,
    action=function(x) 
      lorenz.beta=x
      lorenz:reset()
    end
  }

  params:add{
    type="taper", id = "state1", name = "state1",min=0.000, max=2, default = 0.1,
    action=function(x) 
      lorenz.state[1]=x
      lorenz:reset()
    end
  }
  
  params:add{
    type="taper", id = "state2", name = "state2",min=0.000, max=2, default = 0.0,
    action=function(x) 
      lorenz.state[3]=x
      lorenz:reset()
    end
  }
  
  params:add{
    type="taper", id = "state3", name = "state3",min=0.000, max=2, default = 0.0,
    action=function(x) 
      lorenz.state[3]=x
      lorenz:reset()
    end
  }
  
  
  params:add{
    type="number", id = "steps", name = "steps",min=1, max=100, default = 1,
    action=function(x) 
      lorenz.steps=x
      lorenz:reset()
    end
  }
  params:add{
    type="taper", id = "dt", name = "dt",min=0.001, max=0.05, default = 0.015,
    action=function(x) 
      lorenz.dt=x
      lorenz:reset()
    end
  }
end

return parameters