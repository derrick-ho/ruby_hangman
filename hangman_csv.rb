require 'csv'

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
  @word = choose_word.downcase
  @solved = @word.gsub(/[a-zA-Z]/, '_')
  @alphabet = 'abcdefghijklmnopqrstuvwxyz'
  @fails = 0
  
  return "ng"
end

def save_file
  contents = Dir.mkdir("saves") unless Dir.exists? "saves"

  file = 'saves/save.csv'
  t = Time.new

  unless File.exists? file
    CSV.open(file, 'w',
             :write_headers=> true,
             :headers => ["answer", "solved", "alphabet", "fails", "time"]
            ) do |csv|
      csv << [@word, @solved, @alphabet, @fails, t]
    end
  else
    CSV.open(file, 'a+') do |csv|
      csv << [@word, @solved, @alphabet, @fails, t]
    end
  end

end

def load_file
  begin
    contents = CSV.open "saves/save.csv", headers: true, header_converters: :symbol

    last_i = 0
    contents.each_with_index do |row, i|
      puts i.to_s + ": " + row[:time] + " | Incorrect:" +
           row[:fails] + " | " + row[:solved]

      last_i = i
    end
    puts "Type the number of the save you would like to load."

    select = gets.chomp
    
    return if select.eql? "cancel"

    until select[/^[0-9]*$/] && select.to_i <= last_i
      puts "Select a valid save."
      select = gets.chomp

      return new_game if select.eql? "cancel" 
    end

    # Read past the header
    contents.seek(0)
    contents.readline
    
    select.to_i.times {contents.readline}

    row = contents.readline
    @word = row[:answer]
    @solved = row[:solved]
    @alphabet = row[:alphabet]
    @fails = row[:fails].to_i
    
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
  puts "The correct answer was: " + @word.chomp + "!"
end

hangman
