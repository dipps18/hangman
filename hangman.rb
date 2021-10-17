require 'colorize'
require 'yaml'
module Display
  def display_welcome
    puts "Welcome to Hangman!\n".center(50)
    puts 'Please choose one of the options below (1 or 2)'
    puts "\n1)Start new game".green
    puts '2)Load previous game'.green
  end

  def display_game_started(loaded)
    puts loaded ? "Loaded game started".green : "New game started".green
  end

  def display_letters_length(word)
    puts "length of word: #{word.length}".light_blue
  end

  def display_guesses_left(guesses_left)
    puts "Guesses left: #{guesses_left}\n".light_blue
  end

  def display_result(result)
    result.each{|element| print "#{element} "}
    puts "\n\n"
  end

  def display_game_result(player)
    puts player.guesses_left == 0 ? "No more guesses left, the word was #{@word}".red : "Good job, you guessed the word".green
  end

  def prompt_input
    puts "\nType a letter to check if it exists in the word or type save to save game"
  end

  def display_invalid_input
    puts "Invalid input please try again".red
  end

  def display_repeated
    puts "letter already guessed, please enter another letter".red
  end

  def display_file_not_found
    puts "Error, file not found".red
  end
end

class Game
  include Display

  def initialize(word = "", length = 0, result = "", loaded = false)
    @loaded = loaded
    @length = length
    @result = result
    @word = word
  end

  def play()
    init_word
    @length = @word.length
    display_welcome 
    choice = get_valid_input("not started")
    if choice == "1" 
      player = Player.new()
      @result = Array.new(@length, "_")
      start_game(player) 
    else
      load_game()
    end
  end

  def start_game(player)
    word = @word.delete(player.guesses.join) #stores a copy of the words after removing the guessed words 
    display_game_started(@loaded)
    input = ""
    loop do 
      display_letters_length(@word)
      display_guesses_left(player.guesses_left)
      display_result(@result)
      print player.guesses.join(", ")
      prompt_input
      input = get_valid_input("started", player)
      check_input(input, player, word)
      break if player.guesses_left == 0 || input == "save" || word.empty?
    end
    display_result(@result)
    input == "save" ? save_game(player) : display_game_result(player)
  end    

  def init_word
    num = Random.new.rand(61395)
    file = File.open('5desk.txt','r').readlines.each_with_index{ |line, idx| @word = line.chop if idx == num}
    p @word
  end

  def get_valid_input(string, player = nil)
    loop do
      choice = gets.chomp
      if string == "started"
        if player.guesses.include?(choice.downcase.red) || player.guesses.include?(choice.downcase.green)
          display_repeated 
          next 
        end
        choice == "save" || (choice.length == 1 && choice.match?(/[A-Za-z]/)) ? (return choice) : display_invalid_input 
      else
        choice.match?(/[1-2]/) ? (return choice) : display_invalid_input
      end
    end
  end

  def update_result(input)
    indices = (0...@word.length).select{|i| @word[i].downcase == input.downcase}
    indices.each{|index|@result[index]= input.downcase}
  end

  def check_input(input, player, word)
    return if input == "save"
    if @word.downcase.include?(input.downcase)
      player.guesses.push(input.green)
      update_result(input)
      word.delete!(input)
      puts "Correct guess!"
    else
      player.guesses_left -= 1
      player.guesses.push(input.red)
      puts "Incorrect guess"
    end
  end

  def remove_ext(filename)
    filename = filename[0...filename.index('.')]
  end

  def save_game(player)
    filename = get_file_name
    filename = remove_ext(filename)
    filename.concat(".yaml")
    file = File.open(filename, 'w')
    file.puts YAML.dump({:word => @word,
      :length => @length,
      :guesses_left => player.guesses_left,
      :result => @result,
      :guesses => player.guesses})
    puts "File #{filename} saved"
  end

  def load_game()
    files = Dir.glob("*.yaml").each_with_index{|file, idx| puts "#{idx+1}. #{file}"}
    choice = ""
    loop do
      puts "select choice"
      choice = gets.chomp
      break if choice.to_i!=0 || choice.to_i.between?(1, length)
      display_invalid_input
    end
    filename = files[choice.to_i - 1]
    begin
      data = YAML.load(File.open(filename).read)
      player = Player.new(data[:guesses_left], data[:guesses])
      initialize(data[:word], data[:length], data[:result], true)
      start_game(player)
    rescue 
      display_file_not_found
    end
  end

  def get_file_name
    filename = ""
    loop do
      puts "Enter file name: "
      filename = gets.chomp
      break if filename[0].match?(/[A-Za-z]/)
      puts "Invalid file name please enter again"
    end
    filename
  end
end

class Player 
  attr_accessor :guesses_left, :guesses 

  def initialize(guesses_left = 10, guesses = Array.new)
    @guesses_left = guesses_left
    @guesses = guesses
  end
end

game = Game.new()
game.play

