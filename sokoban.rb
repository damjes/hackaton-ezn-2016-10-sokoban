require 'gosu'

class Stan
  def initialize
    @plansza = [
      [:x, :x, :x, :x, :x, :x, :x],
      [:x, :v, :p, :s, :p, :c, :x],
      [:x, :x, :x, :x, :x, :x, :x]
    ]
    @wymiary = [3, 7]
    @gracz = [2, 1]
    @obrazki = Gosu::Image::load_tiles("grafiki.png", 128, 128)
  end

  def narysuj
    @plansza.each_with_index do |wiersz, y|
      wiersz.each_with_index do |komorka, x|
        num = if(@gracz == [x, y])
          case komorka
          when :x
            0
          when :p
            2
          when :c
            3
          when :s
            4
          when :v
            5
          else
            -1
          end
        else
          case komorka
          when :x
            0
          when :c
            1
          when :s
            4
          when :v
            5
          else
            -1
          end
        end
        @obrazki[num].draw 128*x, 128*y, 0 if num != -1
      end
    end
  end
end

class GameWindow < Gosu::Window
  def initialize
    super 1024,768
    self.caption = "Sokoban"
    @stan = Stan.new
  end

  def update
  end

  def draw
    @stan.narysuj
  end
end

window = GameWindow.new
window.show
