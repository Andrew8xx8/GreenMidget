require File.join(File.dirname(__FILE__), '..', 'spec', 'tester')
include GreenMidget

REPETITIONS             = 5
MESSAGE_LENGTH          = 1000

@train_alternative      = []
@train_null             = []
@known_words            = []
@unknown_words          = []
@unknown_words_fetch    = []
@known_words_fetch      = []

records_count_at_start  = GreenMidgetRecords.count

REPETITIONS.times do
  a = Tester.new_with_random_text(MESSAGE_LENGTH)

  @train_alternative   << Benchmark.measure{ a.classify_as! ALTERNATIVE }.real
  @train_null          << Benchmark.measure{ a.classify_as! NULL        }.real

  @known_words         << Benchmark.measure{ a.classify }.real

  b = Tester.new_with_random_text(MESSAGE_LENGTH)

  @unknown_words       << Benchmark.measure{ b.classify }.real
end

puts "-------------------------------"
puts "Average times in seconds from #{ REPETITIONS } repetitions and #{ MESSAGE_LENGTH } words per message:"
puts "Number of records at start: #{ records_count_at_start } and at the end: #{ GreenMidgetRecords.count }"
puts "-------------------------------"
puts "Training unknown words:                 #{ (@train_alternative.sum.to_f/REPETITIONS).round(4) }"
puts "Training known words:                   #{ (@train_null.sum.to_f/REPETITIONS).round(4) }"
puts "-------------------------------"
puts "Classification of known words:          #{ (@known_words.sum.to_f/REPETITIONS).round(4) }"
puts "Data fetch of known words:              #{ (@known_words_fetch.sum.to_f/REPETITIONS).round(4) }"
puts "-------------------------------"
puts "Classification of unknown words:        #{ (@unknown_words.sum.to_f/REPETITIONS).round(4) }"
puts "Data fetch of unknown words:            #{ (@unknown_words_fetch.sum.to_f/REPETITIONS).round(4) }"
puts "-------------------------------"
