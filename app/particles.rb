$gtk.reset

GRAVITY = 0.05

# base effect class
class ParticleEffect
  attr_accessor :particles, :colours

  def initialize(num_particles)
    @particles = []
    num_particles.times do |i|
      @particles << Particle.new(i, self)
    end
    @colours = colour_seq
  end

  def activate(mouse_x, mouse_y)
    @particles.each { |p| p.activate(mouse_x, mouse_y) }
  end

  def move(x, y, step_x, step_y, keyframe)
    next_x = x + step_x * keyframe
    next_y = y + step_y * keyframe
    return next_x, next_y
  end

  def normalize(x, y)
    theta = Math.atan2(y, x)
    return Math.cos(theta), Math.sin(theta)
  end
end

# smokey rising grey effect
class Smoke < ParticleEffect
  def step
    dir_x, dir_y = normalize((3 * rand) - 1.5, (3 * rand) - 1.5)
    return (2 * rand) * dir_x, (2 * rand) * dir_y
  end

  def move(x, y, step_x, step_y, keyframe)
    next_y = y + Math.cos(Math.atan(step_x) * Math.atan(step_y)) * keyframe * 2
    next_x = x + Math.sin(step_x * step_y) * keyframe
    return next_x, next_y
  end

  def colour_seq
    [
      [[54, 54, 54], 3], # charcoal
      [[127, 127, 180], 4], # cold mid grey
      [[203, 203, 255], 4], # cold pale grey
      [[127, 127, 180], 4], # cold mid grey
      [[54, 54, 54], 3] # charcoal
    ]
  end
end

# swirling blue and purple glowing globe
class Swirl < ParticleEffect
  def step
    dir_x, dir_y = normalize((3 * rand) - 1.5, (3 * rand) - 1.5)
    return (0.5 / rand) * dir_x, (2 * rand) * dir_y
  end

  def move(x, y, step_x, step_y, keyframe)
    next_x = x + Math.sin(step_x * step_y) * keyframe
    next_y = y + Math.cos(step_y * step_x) * keyframe + GRAVITY
    return next_x, next_y
  end

  def colour_seq
    [
      [[32, 32, 126], 5], # dark blue
      [[145, 22, 250], 5], # purple
      [[234, 0, 234], 5],  # magenta
      [[211, 212, 212], 5] # white
    ]
  end
end

# wide explosion with fiery colours
class Explode < ParticleEffect
  def step
    dir_x, dir_y = normalize((3 * rand) - 1.5, (3 * rand) - 1.5)
    return (0.5 / rand) * dir_x, (2 * rand) * dir_y
  end

  def colour_seq
    [
      [[194, 195, 199], 4], # light grey
      [[255, 236, 39], 1], # yellow
      [[255, 163, 0], 2], # orange
      [[255, 0, 77], 3], # red
      [[126, 37, 83], 1] # dark red
    ]
  end
end

# falling toxic greens and greys. twinkle yellow at the end.
class Melt < ParticleEffect
  def step
    dir_x, dir_y = normalize((0.3 * rand) - 0.15, (1.5 * rand) - 1.5)
    return dir_x, (1.5 * rand) * dir_y
  end

  
  def colour_seq
    [
      [[194, 195, 199], 2], # light grey
      [[0, 228, 54], 1], # light green
      [[0, 135, 81], 1], # dark green
      [[95, 87, 79], 1], # dark grey
      [[0, 228, 54], 1], # light green
      [[0, 135, 81], 1], # dark green
      [[95, 87, 79], 1], # dark grey
      [[0, 135, 81], 2], # dark green
      [[95, 87, 79], 1], # dark grey
      [[0, 135, 81], 2], # dark green
      [[95, 87, 79], 2], # dark grey
      [[255, 236, 39], 1] # yellow
    ]
  end
end

# just blow apart
class Disintegrate < ParticleEffect
  def step
    dir_x, dir_y = normalize((5 * rand) - 3, (5 * rand) - 3)
    return (1.5 * rand) * dir_x, (1.5 * rand) * dir_y
  end

  def colour_seq
    [
      [[41, 173, 255], 2], # light blue
      [[194, 195, 199], 4], # light grey
      [[95, 87, 79], 2] # dark grey
    ]
  end
end

# particle class (sprite)
class Particle
  def initialize(id, caller)
    @x = - 10
    @y = - 10
    @w = 4
    @h = 4
    @path = 'sprites/white.png'
    @active = false
    @id = id
    @effect = caller
    @keyframe = 3

    @step_x, @step_y = @effect.step
    @step_y_ref = @step_y

    $args.outputs.static_sprites << self
  end

  # set the particle in motion
  def activate(x, y)
    @active = true
    @x = x
    @y = y
    @step_y = @step_y_ref
    @colour_count = 0
    @colour_ind = 0
    @colour_num = 0
  end

  # movement, colour changes and death
  def move
    # don't calculate move unless this is a keyframe
    return unless @active && $args.tick_count % @keyframe == @id % @keyframe

    # get the x, y change from effect object
    @x, @y = @effect.move(@x, @y, @step_x, @step_y, @keyframe)

    # apply gravity
    @step_y -= GRAVITY * @keyframe

    # die if out of bounds or out of colours
    if @colour_ind == @effect.colours.count || @x > 1280 || @x < -4 || @y < -4
      die
      return
    end

    # chance of changing colour
    return if rand(2).zero?

    # set sprite colour
    c = @effect.colours[@colour_ind]
    @r = c[0][0]
    @g = c[0][1]
    @b = c[0][2]

    # figure out which colour is next
    @colour_num += 1
    if @colour_num > c[1] - 1
      @colour_num = 0
      @colour_ind += 1
    end
  end

  # make inactive and move off screen
  def die
    @active = false
    @x = -999
  end

  # wizardry
  def draw_override(ffi_draw)
    move
    ffi_draw.draw_sprite_3 @x + 4, @y, @w, @h, # x, y, w, h,
                           @path, # path,
                           nil, # angle,
                           nil, @r, @g, @b, # alpha, red_saturation, green_saturation, blue_saturation
                           nil, nil, # flip_horizontally, flip_vertically,
                           nil, nil, nil, nil, # tile_x, tile_y, tile_w, tile_h
                           nil, nil, # angle_anchor_x, angle_anchor_y,
                           nil, nil, nil, nil # source_x, source_y, source_w, source_h
  end

  # blah
  def serialize
    { step_x: step_x, step_y: step_y, r: r, g: g, b: b }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end
end
