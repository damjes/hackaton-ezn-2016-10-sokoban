require 'gosu'

class Stan
	attr_reader :brakuje
	def initialize
		@plansza = [
			[:p, :p, :p, :p, :p, :p, :p, :p, :x, :x, :x, :x, :x, :p, :p, :p, :p],
			[:p, :p, :p, :p, :p, :p, :p, :p, :x, :p, :p, :p, :x, :x, :x, :x, :x],
			[:p, :p, :p, :p, :p, :p, :p, :p, :x, :p, :x, :s, :x, :x, :p, :p, :x],
			[:p, :p, :p, :p, :p, :p, :p, :p, :x, :p, :p, :p, :p, :p, :s, :p, :x],
			[:x, :x, :x, :x, :x, :x, :x, :x, :x, :p, :x, :x, :x, :p, :p, :p, :x],
			[:x, :c, :c, :c, :c, :p, :p, :x, :x, :p, :s, :p, :p, :s, :x, :x, :x],
			[:x, :c, :c, :c, :c, :p, :p, :p, :p, :s, :p, :s, :s, :p, :x, :x, :p],
			[:x, :c, :c, :c, :c, :p, :p, :x, :x, :s, :p, :p, :s, :p, :p, :x, :p],
			[:x, :x, :x, :x, :x, :x, :x, :x, :x, :p, :p, :s, :p, :p, :x, :x, :p],
			[:p, :p, :p, :p, :p, :p, :p, :p, :x, :p, :s, :p, :s, :p, :p, :x, :p],
			[:p, :p, :p, :p, :p, :p, :p, :p, :x, :x, :x, :p, :p, :p, :p, :x, :p],
			[:p, :p, :p, :p, :p, :p, :p, :p, :p, :p, :x, :p, :p, :p, :p, :x, :p],
			[:p, :p, :p, :p, :p, :p, :p, :p, :p, :p, :x, :x, :x, :x, :x, :x, :p],
		]
		@gracz = [14, 7]
		@brakuje = 12
		@obrazki = Gosu::Image::load_tiles("grafiki.png", 32, 32)
		@przes = Gosu::Sample.new("dzwieki/przes.wav")
		@zalicz = Gosu::Sample.new("dzwieki/zalicz.wav")
		@wygrana = Gosu::Sample.new("dzwieki/wygrana.wav")
		@krok = Gosu::Sample.new("dzwieki/krok.wav")
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
				@obrazki[num].draw 32*x+48, 32*y+32, 0 if num != -1
			end
		end
	end

	def probuj_przesunac deltax, deltay
		plus_1 = @plansza[@gracz[1] + deltay][@gracz[0] + deltax]
		if plus_1 == :p or plus_1 == :c
			@gracz = [@gracz[0] + deltax, @gracz[1] + deltay]
			@krok.play
		end
		if plus_1 == :s or plus_1 == :v
			plus_2 = @plansza[@gracz[1] + 2*deltay][@gracz[0] + 2*deltax]
			if plus_2 == :p or plus_2 == :c
				if plus_1 == :s
					@plansza[@gracz[1] + deltay][@gracz[0] + deltax] = :p
				else
					@plansza[@gracz[1] + deltay][@gracz[0] + deltax] = :c
					@brakuje += 1
				end
				if plus_2 == :p
					@plansza[@gracz[1] + 2*deltay][@gracz[0] + 2*deltax] = :s
					@przes.play
				else
					@plansza[@gracz[1] + 2*deltay][@gracz[0] + 2*deltax] = :v
					@brakuje -= 1
					if @brakuje == 0
						@wygrana.play
				 else
						@zalicz.play
					end
				end
				@gracz = [@gracz[0] + deltax, @gracz[1] + deltay]
			end
		end
	end

end

class GameWindow < Gosu::Window
	def initialize
		super 640, 480
		self.caption = "Sokoban"
		@stan = Stan.new
		@blokada = 0
		@duzy_font = Gosu::Font.new(160)
		@maly_font = Gosu::Font.new(20)
	end

	def update
		close if Gosu::button_down? Gosu::KbEscape
		if @blokada > 0 or @stan.brakuje == 0
			@blokada -= 1
		else
			if Gosu::button_down? Gosu::KbLeft or Gosu::button_down? Gosu::GpLeft
				@stan.probuj_przesunac -1, 0
				@blokada = 10
			end
			if Gosu::button_down? Gosu::KbRight or Gosu::button_down? Gosu::GpRight
				@stan.probuj_przesunac 1, 0
				@blokada = 10
			end
			if Gosu::button_down? Gosu::KbDown or Gosu::button_down? Gosu::GpDown
				@stan.probuj_przesunac 0, 1
				@blokada = 10
			end
			if Gosu::button_down? Gosu::KbUp or Gosu::button_down? Gosu::GpUp
				@stan.probuj_przesunac 0, -1
				@blokada = 10
			end
		end
	end

	def draw
		if @stan.brakuje == 0
			@duzy_font.draw("Wygrana", 12, 12, 3, 1, 1, Gosu::Color::YELLOW)
		else
			@stan.narysuj
			status = 'Brakuje: ' + @stan.brakuje.to_s
			@maly_font.draw(status, 11, 11, 2, 1, 1, Gosu::Color::WHITE)
			@maly_font.draw(status, 10, 10, 3, 1, 1, Gosu::Color::GREEN)
		end
	end
end

window = GameWindow.new
window.show
