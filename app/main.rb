$gtk.reset

require 'app/grot_debug.rb'
require 'app/particles.rb'

def prepare(args)
  args.state.prepped = true
  $effect = [
    Disintegrate.new(128),
    Melt.new(64),
    Explode.new(256),
    Smoke.new(512),
    Swirl.new(512)
  ]
  args.state.effect_counter = 0
end

def handle_inputs(args)
  if args.inputs.mouse.down || args.inputs.keyboard.key_down.space
    $effect[args.state.effect_counter].activate(*args.inputs.mouse.point)
    args.state.effect_counter += 1
    args.state.effect_counter = 0 if args.state.effect_counter == $effect.count
  end
end

def tick(args)
  $gtk.suppress_mailbox = false
  GROT.debug(true) if args.state.tick_count.zero?
  GROT.tick_start
  args.outputs.background_color = [0, 0, 0]
  prepare(args) unless args.state.prepped == true
  handle_inputs(args)
  GROT.tick_end
end
