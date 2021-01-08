# Particle Effects
Some particle effects for DragonRuby.

To use: require the `app/particles.rb` file.

To create the particle effect:

To avoid slowing down the game, particle effects must be created at the start (tick 0).

e.g.

```$smoke = Smoke.new(512) if args.state.tick_count.zero?```

Effects accept one parameter: the number of particles to create.

To activate an effect:

```$smoke.activate(*args.inputs.mouse.point)```

Activate accepts two parameters representing the x and y location for the effect to appear.

### Creating or customizing effects

You can create a new effect by inheriting ParticleEffect.

```ruby
# smokey rising grey effect
class Smoke < ParticleEffect

  # this mandatory method must return the basic movement of the particle.
  # note that two values are returned (x movement and y movement).
  def step
    dir_x, dir_y = normalize((3 * rand) - 1.5, (3 * rand) - 1.5)
    return (2 * rand) * dir_x, (2 * rand) * dir_y
  end

  # this optional method allows you to calculate the next x, y position of the particle
  # based on the current position, the base x, y movement of the particle
  # and the 'keyframe' value (the number of frames to wait before drawing).
  # If this method is omitted, movement is based on the calculation in the step method
  def move(x, y, step_x, step_y, keyframe)
    next_y = y + Math.cos(Math.atan(step_x) * Math.atan(step_y)) * keyframe * 2
    next_x = x + Math.sin(step_x * step_y) * keyframe
    return next_x, next_y
  end

  # this mandatory method returns the colours used by the effect
  # each colour is accompanied by the number of times the colour will
  # repeat before moving on to the next colour.
  # Particles die when there are no more colours to display.
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
```
