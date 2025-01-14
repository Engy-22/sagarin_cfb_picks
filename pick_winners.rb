# Pick the winners of this week's CFB games by cross-referencing a formatted
# list of Sagarin ratings with a slate of games.
#
# Will fail if ratings.txt is not present.
require 'text'
require 'active_support/core_ext'

def load_ratings()
  ratings = open('ratings.txt').readlines
  ratings = ratings.map { |x| x[0..29].rstrip.lstrip.gsub(/(\s)(\d)/, ':\2').split(':') }
  ratings = ratings.each.map { |el| [el.first.lstrip.rstrip, el.second] }
  ratings.pop

  hash = {}
  ratings.each { |el| hash[el.first] = el.second.to_f }

  return hash
end

def load_slate(str="")
  # Loads a slate of games from the str arg or from slate.txt.
  # Marks favorite, underdog, home team, and Yahoo table index.
  str = str.lstrip.rstrip.split("\n")
  slate = str.empty? ? open('slate.txt').readlines : str
  puts slate
  slate = slate.map.with_index do |line, index|
    line = line.rstrip.lstrip.split(':')
    output = { favorite: line.first,
               underdog: line.second,
               home_underdog: line.third.nil? ? false : true,
               index: index }
  end
end

def pick(game, ratings)
  home_advantage = game[:home_underdog] ? -2.64 : 2.64 

  game[:spread] = ratings[game[:favorite]] - ratings[game[:underdog]]
  game[:spread] += home_advantage
  game[:spread] = game[:spread].round(2)

  game[:upset] = game[:spread] > 0 ? false : true

  game[:arrow] = game[:upset] ? "->" : "  "

  return game
end

def print_pick(game, pad_width)
  favorite  = "#{game[:favorite].ljust pad_width}"
  underdog   = "#{game[:underdog].ljust pad_width}"
  spread  = game[:spread].round(0).to_s.rjust 3
  conf    = game[:confidence].to_s.rjust 2

  return "#{favorite}\t#{game[:arrow]}\t#{underdog}\t[#{conf}]\t[#{spread}]"
end

def pick_winners(str="")
  ratings      = load_ratings
  slate        = load_slate(str)
  puts slate
  picks        = []

  slate.each do |game|
     begin
         picks.push pick game, ratings
     rescue
          puts "Failed lookup for #{game.to_s}"
     end
  end

  picks.sort_by! { |game| game[:spread].abs }

  picks.each.with_index { |pick, index| pick[:confidence] = index + 1 }

  picks.sort_by! { |game| game[:index] }

  return picks
end

def print_winners(picks)
  longest_name = (picks.map { |pick| [pick[:favorite].length, pick[:underdog].length].max }).max

  puts "****** PICKS ******".center 80
  picks.each { |game| puts print_pick game, longest_name }
  puts "\n"

  puts "****** BLOWOUTS ******".center 80

  results = picks.sort_by { |game| -game[:spread] }
  results[0..2].each { |game| puts print_pick game, longest_name }
end

def picks_as_json(picks)
  output = []
  picks.each { |pick| output.push [pick[:upset], pick[:confidence]] }
  output.map! { |pick| { upset: pick.first, confidence: pick.second } }
  return output
end

picks = pick_winners
print_winners(picks)
