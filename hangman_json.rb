require 'json'

# Print introduction screen
# Returns: given command
def print_start
  puts "H   H    A    NN   N  GGGG  MM   MM    A    NN   N"
  puts "HHHHH   AAA   N N  N G      M M M M   AAA   N N  N"
  puts "H   H  A   A  N  N N G   GG M  M  M  A   A  N  N N"
  puts "H   H A     A N   NN  GGGG  M     M A     A N   NN"
  puts ""
  puts "Valid commands: new, cont, exit"

  valid_cmd = ["new", "cont", "exit"]
  response = gets.chomp.downcase
  until valid_cmd.any? response
    puts "Please enter a valid command: new, cont, exit"
    response = gets.chomp.downcase
  end

  response
end

def choose_word
  begin
    #Likely poor runtime with big files
    chosen = File.readlines("5desk.txt").sample
    
    chosen = File.readlines("5desk.txt").sample until (chosen.length > 5 &&
                                                       chosen.length < 14)

  rescue
    "Invalid File"
  end
  
  chosen.chomp
end

def new_game
  @word = choose_word.downcase.chomp
  @solved = @word.gsub(/[a-zA-Z]/, '_')
  @alphabet = 'abcdefghijklmnopqrstuvwxyz'
  @fails = 0
  
  return "ng"
end

def save_file
  contents = Dir.mkdir("saves") unless Dir.exists? "saves"

  file = 'saves/save.json'
  
  t = Time.new
  save_hash = {
    :answer => @word,
    :solved => @solved,
    :alphabet => @alphabet,
    :fails => @fails,
    :time => t
  }

  File.open(file, 'w') do |row|
    row.write(save_hash.to_json)
  end
end

def load_file
  begin
    contents = File.read('saves/save.json')
    save = JSON.parse(contents)

    @word = save["answer"]
    @solved = save["solved"]
    @alphabet = save["alphabet"]
    @fails = save["fails"].to_i    
  rescue
    puts "There are no saves"
  end
  # TODO: some error checking here for the file eventually
end

def prompt
  puts "----------------------------------------------------"
  puts (8 - @fails).to_s + " Tries Remaining"
  puts "Guess a letter:"

  # Hangman Noose
  puts " _______"
  puts "|       |"
  puts "|       ^"

  #Head
  if    @fails < 1
    puts "|"
  elsif @fails > 7
    puts "|     (x x)"
  elsif @fails > 6
    puts "|     (x  )"
  else
    puts "|     (   )"
  end
  
  #Body
  print "|"
  print "      /" if @fails > 1
  print "|"       if @fails > 2
  print "\\"      if @fails > 3
  puts ""

  #Legs
  print "|"
  print "      /" if @fails > 4
  print " \\"     if @fails > 5
  puts ""

  # Finish Stage
  puts "|"
  puts "|"
  puts "=========="
  
  puts @solved
end

def guess
  attempt = gets.chomp

  return "exit" if attempt.eql? "exit"

  # Check if alphabet letter and if it's a valid choice.
  until ((attempt =~ /[A-Za-z]/) &&
         (@alphabet.include? attempt[0].downcase))
    puts "Please type a valid letter or exit."
    attempt = gets.chomp

    return "exit" if attempt.eql? "exit"
  end

  @alphabet.sub!(attempt[0],"")
  
  if @word.include? attempt
    @word.each_char.with_index do |c, i|
      @solved[i] = attempt if c==attempt
    end
    
    true
  else
    false
  end
end

def hangman
  choice = print_start

  if choice.eql? "new"
    new_game
  elsif choice.eql? "cont"
    load_file
  else
    puts "Goodbye!"
    return
  end

  # Main Game Loop
  until (@fails > 7 || @word.eql?(@solved))
    
    puts "----------------------------------------------------"
    puts "Remaining letters: " + @alphabet

    prompt

    try = guess

    if try.eql? "exit"
      puts "Would you like to save? (y/n)"
      response = gets.chomp.downcase
      if response.eql? "n"
        return
      elsif response.eql? "y"
        #save_state = word + "," + solved + "," + alphabet + "," + fails.to_s
        save_file()
        return
      else
        until ["y","n"].any? response
          puts "Please type in a valid answer."
          puts "Would you like to save? (y/n)"
          response = gets.chomp.downcase
        end
      end
    elsif try == false
      @fails += 1
    end
  end

  # Game Over
  prompt
  puts "You died." if @fails > 7
  puts "You win!" if @fails < 8
  puts "The correct answer was: " + @word + "!"
end

hangman
