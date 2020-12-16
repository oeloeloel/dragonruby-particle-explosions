$gtk.reset seed: Time.now.to_i

# METHOD = :sprites
METHOD = :static_sprites

# puts "++++++++++++++++++ RESET +++++++++++++++++++++"

#   Creates a few different effects using particles
#   explode: fly apart dramatically and burn with flaming colours
#   melt: fall apart in a downward direction while turning toxic green
#   disintegrate: break apart less dramatically without burning colours

#   to do

#   particles should allow init of step and direction
#   so an exploding sprite would appear to continue in the same
#   direction as it explodes rather than suddenly stop

def tick(args)
  # black background
  args.outputs.solids << [0, 0, 1280, 720, 0, 0, 0]

  # create the objects at the start rather than slow things down later
  args.state.explode ||= ParticleEffect.new(args, ExplodeStrategy.new)
  args.state.melt ||= ParticleEffect.new(args, MeltStrategy.new)
  args.state.disintegrate ||= ParticleEffect.new(args, DisintegrateStrategy.new)

  # calculate next moves etc.
  args.state.explode.update
  args.state.melt.update
  args.state.disintegrate.update

  # perform the effects when spacebar is pressed
  # or the mouse is clicked
  if args.inputs.keyboard.key_down.space || args.inputs.mouse.click
    args.state.explode.activate(640, 640)
    args.state.melt.activate(640, 440)
    args.state.disintegrate.activate(640, 240)
  end

  # some useful stuff
  debug args
end

# tells ParticleEffect how to behave in case of an explode effect
# blasts apart with a burning red colour palette
class ExplodeStrategy
  # how big is it
  def num_particles
    256
  end

  # what colours each particle will cycle through
  # (same colour repeated keeps it going for longer)
  def colours
    [
      [194, 195, 199], [194, 195, 199], [194, 195, 199], [194, 195, 199], # light grey
      [255, 236, 39], # yellow
      [255, 163, 0], [255, 163, 0], # orange
      [255, 0, 77], [255, 0, 77], [255, 0, 77], # red
      [126, 37, 83] # dark red
    ]
  end

  # calculates the next move for each particle in this effect
  # this is only called once and the particle will use the same
  # movement each frame while accounting for gravity
  # this one spreads the explosion out horizontally
  def step
    dir = normalize({ x: (3 * rand) - 1, y: (3 * rand) - 1 })
    { x: (1.5 / rand) * dir.x, y: (1.5 * rand) * dir.y }
  end
end

# tells ParticleEffect how to behave in case of an melt effect
# melts and drops down with a toxic green colour palette
class MeltStrategy
  def num_particles
    64
  end

  # toxic greens and greys. twinkle yellow at the end.
  def colours
    [
      [194, 195, 199], [194, 195, 199], # light grey
      [0, 228, 54], # light green
      [0, 135, 81], # dark green
      [95, 87, 79], # dark grey
      [0, 228, 54], # light green
      [0, 135, 81], # dark green
      [95, 87, 79], # dark grey
      [0, 135, 81], [0, 135, 81], # dark green
      [95, 87, 79], # dark grey
      [0, 135, 81], [0, 135, 81], # dark green
      [95, 87, 79], # dark grey
      [255, 236, 39] # yellow
    ]
  end

  # calculates the next move for each particle in this effect
  # mostly fall down, slightly spread out
  def step
    dir = normalize({ x: (0.3 * rand) - 0.15, y: (1.5 * rand) - 1.5 })
    { x: dir.x, y: (1.5 * rand) * dir.y }
  end
end

# tells ParticleEffect how to behave in case of a disintegrate effect
# blasts apart in a round shape without a burning red effect.
# colours can be swapped out for the colours in the sprite
class DisintegrateStrategy
  def num_particles
    64
  end

  def colours
    [
      [41, 173, 255], [41, 173, 255], # light blue
      [194, 195, 199], [194, 195, 199], [194, 195, 199], [194, 195, 199], # light grey
      [95, 87, 79], [95, 87, 79] # dark grey
    ]
  end

  def step
    dir = normalize({ x: (5 * rand) - 3, y: (5 * rand) - 3 })
    { x: (1.5 * rand) * dir.x, y: (1.5 * rand) * dir.y }
  end
end

# parts that are common to all the effects
class ParticleEffect
  GRAVITY = 0.05
  # set up the bounds beyond which particles can be marked as inactive
  # this is probably always going to be the left, bottom, width and height of
  # the window
  # since we have gravity, we won't test for particles going off the top
  # because they will come back down
  BOUNDS = [0, 0, 1280, -1]

  def initialize(args, strategy)
    @args = args
    @strategy = strategy

    # get effect specific values from supplied strategy
    @num_particles = @strategy.num_particles
    @colours = @strategy.colours

    # initialize particles
    @particles ||= @num_particles.map do
      p = Particle.new(
        @args,
        @colours,
        # @gravity,
        GRAVITY,
        BOUNDS
      )
      if METHOD == :static_sprites
        @args.outputs.static_sprites << p
      end
      p
    end
  end

  # called when it's time to make the effect happen
  # supply x and y coordinates
  def activate(origin_x, origin_y)
    # get the movement for each particle from the strategy
    # and activate the particle
    @particles.map do |p|
      p.activate origin_x, origin_y, @strategy.step.x, @strategy.step.y
    end
  end

  # tell particles its a new frame
  def update
    @particles.map { |p| p.update }

    if METHOD == :sprites
      @args.outputs.sprites << @particles.map do |p|
        p if p.active
      end
    end
  end

  # the small print
  def serialize
    {}
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end
end

# individual particle
class Particle
  # instances will be fed to args.outputs.sprites
  attr_sprite

  # ParticleEffect will get or set these
  attr_accessor :step_x, :step_y, :r, :g, :b, :active

  # do everything that can be done early to go faster later
  def initialize(args, colours, gravity, bounds)
    @args = args
    @colours = colours
    @gravity = gravity
    @bounds = bounds
    @x = x
    @y = y
    @w = 4
    @h = 4
    @path = 'sprites/white.png'
    @active = false
  end

  # time to dance
  def activate(particle_x, particle_y, step_x, step_y)
    # active will stay true as long as the particle is inside bounds
    # and we haven't run out of colours to display
    @active = true
    @x = particle_x
    @y = particle_y
    @step_x = step_x
    @step_y = step_y
    @colour_count = 1
    @r = @colours[0][0]
    @g = @colours[0][1]
    @b = @colours[0][2]
  end

  def update
    return if @active != true

    # update position
    @x += @step_x
    @y += @step_y
    @step_y -= @gravity

    # 1 in 5 chance of colour shifting to next.
    # Room for improvement here
    if rand(5).zero?
      if check_still_alive == false
        # hide from view
        @x = -999
        @active = false
      else
        @r = @colours[@colour_count][0]
        @g = @colours[@colour_count][1]
        @b = @colours[@colour_count][2]
        @colour_count += 1
      end
    end

    # DON'T DO THIS. FEEDING SPRITES 
    # ONE AT A TIME IS SUPER SLOW
    # DO IT FROM THE OUTSIDE USING
    # MAP OR EACH
    # sacrifice self to the beast
    # @args.outputs.sprites << self
  end

  # check to see if particle should remain active
  def check_still_alive
    return false if @colour_count >= @colours.count
    return false if @bounds[0] != -1 && @x < @bounds[0]
    return false if @bounds[1] != -1 && @y < @bounds[1]
    return false if @bounds[2] != -1 && @x > @bounds[0] + @bounds[2]
    return false if @bounds[3] != -1 && @y > @bounds[1] + @bounds[3]
  end

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

# a fun bit of geometry, used by the strategies
def normalize(vec)
  theta = Math.atan2(vec.y, vec.x)
  { x: Math.cos(theta), y: Math.sin(theta) }
end

def debug(args)
  # reset DR: press 1
  $gtk.reset seed: Time.now.to_i if args.inputs.keyboard.key_down.one

  # crude instructions and FPS display
  args.outputs.labels << [10, 30,
                          "Click or hit the spacebar. FPS: #{args.gtk.current_framerate.to_i}",
                          255, 255, 255, 255]
end
