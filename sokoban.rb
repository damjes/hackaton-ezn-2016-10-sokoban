require 'gosu'

class Stan
	attr_reader :brakuje
	def initialize
		@brakuje = 0
		czytaj_plik 'plansza.ppm'
		@obrazki = Gosu::Image::load_tiles("grafiki.png", 64, 64)
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
				@obrazki[num].draw 64*x+256, 64*y+48, 0 if num != -1
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

	def czytaj_kolor strumien
		r = strumien.getbyte
		g = strumien.getbyte
		b = strumien.getbyte

		if r == 0
			if g == 0
				if b == 0
					# czarny
					return :p
				elsif b == 255
					# niebieski
					return :gracz
				end
			elsif g == 255
				if b == 0
					# zielony
					return :s
				end
			end
		elsif r == 255
			# czerwona składowa to pole docelowe
			if g == 0
				if b == 0
					# czerwony
					return :c
				elsif b == 255
					# fioletowy
					# niebieski na czerwonym inaczej mówiąc
					return :gracz_na_c
				end
			elsif g == 255
				if b == 0
					# żółty
					# zielony na czerwonym
					return :v
				elsif b == 255
					# biały
					return :x
				end
			end
		end

		raise 'Nieznany kolor'
	end

	def przetworz_kolor strumien, x, y
		kolor = czytaj_kolor strumien
		if kolor == :gracz
			@gracz = [x, y]
			return :p
		elsif kolor == :gracz_na_c
			@gracz = [x, y]
			return :c
		else
			return kolor
		end
	end

	def czytaj_macierz strumien, x, y
		@plansza = []
		y.times do |nr_wiersza|
			wiersz = []
			x.times do |nr_kolumny|
				symbol = przetworz_kolor strumien, nr_kolumny, nr_wiersza
				wiersz << symbol
				@brakuje += 1 if symbol == :s
			end
			@plansza << wiersz
		end
	end

	def czytaj_plik plik
		File.open(plik, 'r') do |uchwyt|
			raise 'Wymagany tryb P6' unless uchwyt.gets.chomp == 'P6'
			linia = uchwyt.gets
			while linia.chr == '#'
				linia = uchwyt.gets
			end
			wymiary = linia.split
			raise 'Wymagana paleta 255 wartości na kanał' unless uchwyt.gets.chomp == '255'
			czytaj_macierz uchwyt, wymiary[0].to_i, wymiary[1].to_i
		end
	end
end

class GameWindow < Gosu::Window
	def initialize
		super 1280, 800, true
		self.caption = "Sokoban"
		@stan = Stan.new
		@blokada = 0
		@czas = 0
		@duzy_font = Gosu::Font.new(300)
		@maly_font = Gosu::Font.new(36)
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
		@czas += 1
	end

	def draw
		if @stan.brakuje == 0
			@duzy_font.draw_text("Wygrana", 50, 100, 3, 1, 1, Gosu::Color::YELLOW)
		else
			@stan.narysuj
			status = 'Brakuje: ' + @stan.brakuje.to_s + '   Czas: ' + (@czas/60).to_s
			@maly_font.draw_text(status, 11, 11, 2, 1, 1, Gosu::Color::WHITE)
			@maly_font.draw_text(status, 10, 10, 3, 1, 1, Gosu::Color::GREEN)
		end
	end
end

GameWindow.new.show
