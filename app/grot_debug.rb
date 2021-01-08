$gtk.reset

module GROT
  def self.debug(active, color: [127, 127, 127, 255])
    $grot_debug = active ? Debug.new(color) : nil
  end

  def self.tick_start
    return unless $grot_debug

    $grot_debug.tick_start
  end

  def self.tick_end
    return unless $grot_debug

    $grot_debug.tick_end
  end

  def self.watch(&block)
    return unless $grot_debug

    $grot_debug.watch(&block)
  end

  # the debug class
  class Debug
    attr_accessor :watchlist

    def initialize(color)
      @watchlist = []
      @color = color

      @tick_time = [0]
      @tick_time_sum = 0
      @sys_time_diff = 0
      @system_time = [0]
      @full_tick = [0]
      @full_tick_time_sum = 0

      watch { "FPS: #{$gtk.current_framerate.to_i}" }
      watch { format('Time in your tick: %.4f', @tick_time_sum) }
      watch { format('Time in my tick: %.4f', @sys_time_diff.to_f) }
    end

    def watch(&block)
      @watchlist << block
    end

    def tick_start
      @starting = Time.now.to_f
    end

    def tick_end
      calc
      render_watchlist
    end

    def calc
      @system_time.unshift(Time.now.to_f)
      @tick_time.unshift(@system_time[0] - @starting)
      @full_tick.unshift(@system_time[0] - @system_time[1])
      if @tick_time.length < 60
        @tick_time_sum += @tick_time[0]
      else
        @tick_time_sum += (@tick_time[0] - @tick_time[-1])
        @tick_time.pop
        @full_tick.pop
        @system_time.pop
      end
      @sys_time_diff = (@system_time[0] - @system_time[-1]).to_f / 60.0
    end

    def render_watchlist
      $gtk.args.outputs.labels << @watchlist.map_with_index do |watched, i|
        {
          x: 5, y: 720 - (i * 20),
          text: watched.call,
          size_enum: -1.5,
          r: @color[0],
          g: @color[1],
          b: @color[2],
          a: @color[3]
        }
      end
    end
  end
end
