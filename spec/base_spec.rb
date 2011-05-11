# Copyright (c) 2011, SoundCloud Ltd., Nikola Chochkov
require 'spec_helper'
require File.join(File.dirname(__FILE__), 'tester')

describe SpamClassifier::Base do
  include SpamClassifier

  before(:each) do
    SpamClassificationIndex.delete_all
    [
      {:key => "word::this",                                      :spam_count => 701,  :ham_count =>   11},
      {:key => "word::test",                                      :spam_count => 9,    :ham_count =>   71},
      {:key => "word::goes",                                      :spam_count => 90,   :ham_count =>   90},
      {:key => "word::rid",                                       :spam_count => 311,  :ham_count =>  290},
      {:key => "word::dirty",                                     :spam_count => 222,  :ham_count =>   45},
      {:key => "word::spam",                                      :spam_count => 11,   :ham_count =>  133},
      {:key => "word::words",                                     :spam_count => 6,    :ham_count =>  811},
      {:key => "word::zero",                                      :spam_count => 0,    :ham_count =>    0},
      {:key => "with_feature::url_in_text",                       :spam_count => 440,  :ham_count =>   40},
      {:key => "with_feature::email_in_text",                     :spam_count => 112,  :ham_count =>    9},
      {:key => "training_examples_with_feature::any",             :spam_count => 1000, :ham_count => 1000},
      {:key => "training_examples_with_feature::url_in_text",     :spam_count => 1000, :ham_count => 1000},
      {:key => "training_examples_with_feature::email_in_text",   :spam_count => 1000, :ham_count => 1000},
    ].each do |entry|
      key = entry[:key]
      instance = case
        when key =~ /^word::/ then
          Words.create!(key)
        when key =~ /^with_feature::/ then
          Features.create!(key)
        when key =~ /^training_examples_with_feature::/ then
          TrainingExamples.create!(key)
        else
          raise ArgumentError.new('Bad entry')
      end
      instance.update_attributes({ :spam_count => entry[:spam_count], :ham_count => entry[:ham_count] })
      SpamClassificationIndex.write!
    end
  end

  it "should calculate spam probability of 2.43e-06 for 'test goes words'" do
    Tester.new('test goes words').category_probability(:spam).
      should == 9.0/1000 * 90.0/1000 * 6.0/1000 * 1000.0/(1000+1000)
  end

  it "should calculate ham probability of 0.00259 for 'test goes words'" do
    Tester.new('test goes words').category_probability(:ham).round(5).
      should == (71.0/1000 * 90.0/1000 * 811.0/1000 * 1000.0/(1000+1000)).round(5)
  end

  describe 'SpamClassifierProbabilities#criterion_ratio' do
    it "should be smaller for a smaller number of spammy words" do
      Tester.new('this dirty test').criterion_ratio.should > Tester.new('this test').criterion_ratio
    end
  end

  describe "#criterion_ratio" do
    it "should add unknown words to the dictionary before classification" do
      Tester.new('newword needs to pass heuristics').classify
      Words['newword'][:spam].should == 0
      Words['newword'][:spam].should == 0
    end

    it "considers 'test goes words' ham" do
      Tester.new('test goes words').criterion_ratio.should < 1
    end

    it "considers 'rid goes dirty' spam" do
      Tester.new('rid goes dirty').criterion_ratio.should >= SPAM_THRESHOLD
    end

    it "doesn't know whether 'zero goes rid' is spam or not" do
      Tester.new('zero goes rid').criterion_ratio.between?(1, SPAM_THRESHOLD).should be_true
    end

    it "thinks of 'test boss@offshore.com' as more spam than just 'test'" do
      Tester.new('test boss@offshore.com').criterion_ratio.
        should > Tester.new('test').criterion_ratio
    end

    it "thinks of 'test www.offshore.com' as more spam than just 'test'" do
      Tester.new('test www.offshore.com').criterion_ratio.
        should > Tester.new('test').criterion_ratio
    end

    it "will tolerate urls coming from known sites" do
      Tester.new('test www.offshore.com').criterion_ratio.should >
      Tester.new('test www.soundcloud.com').criterion_ratio
    end

    it "should say DUNNO if it doesnt have neither :spam nor :ham score for a message" do
      Tester.new('zero newword heuristicspass').criterion_ratio.between?(1, SPAM_THRESHOLD).should be_true
    end

    it "should say IS_SPAM if it has spam score for a message and doesn't have ham score for it" do
      a = Tester.new('nosuchword nowordsuch heuristicspass')
      a.category_probability(:spam).should == 0.0
      a.category_probability(:ham).should == 0.0
      a.criterion_ratio.between?(1, SPAM_THRESHOLD).should be_true
      a.classify_as!(:spam)
      a.criterion_ratio.should >= SPAM_THRESHOLD
    end

    it "should say IS_HAM if it has ham score for a message and doesn't have spam score for it" do
      a = Tester.new('suchwordno nowordsuch heuristicspasss')
      a.category_probability(:spam).should == 0.0
      a.category_probability(:ham).should == 0.0
      a.criterion_ratio.between?(1, SPAM_THRESHOLD).should be_true
      a.classify_as!(:ham)
      a.criterion_ratio.should < 1
    end
  end

  describe "#classify_as!" do
    it "should increase the index counts of the classified words" do
      lambda {
        Tester.new('zero').classify_as!(:ham)
      }.should change { Words['zero'][:ham] }.by(1)
    end
    it "should increment the learning examples count for all features" do
      FEATURES.each do |feature|
        lambda {
          Tester.new('zero').classify_as!(:ham)
        }.should change { TrainingExamples[feature][:ham] }.by(1)
      end
    end
    it "should not add new records for known keys" do
      a = Tester.new 'stuff unknown sofar'
      lambda {
        a.classify_as! :spam
      }.should change { SpamClassificationIndex.count }.by(3)
      lambda {
        a.classify_as! :ham
      }.should_not change { SpamClassificationIndex.count }
    end
  end

  describe "#words" do
    it "should ignore words less than 3 characters" do
      Tester.new('is 2 ch').words.should == []
    end
    it "should break large character strings into chunks of 20 bytes" do
      Tester.new('s'*20 + '111').words.should == ['s'*20, '111']
    end
    it "should bring uppercase to lowcase" do
      Tester.new('HOWBIG').words.should == ['howbig']
    end
    it "should not consider parts of email address as individual words" do
      Tester.new('friend@soundcloud.com').words.should == []
    end
    it "should not consider parts of website url as individual words" do
      Tester.new('www.myguy.com http://wearegeil.org').words.should == []
    end
  end

  describe "#pass_ham_heuristics?" do
    # it "shouldn't deal with comments having no url/email and less than LOWER_WORDS_LIMIT_FOR_COMMENTS words" do
    #   Tester.new('that seems quite alright', User.new, Comment).pass_ham_heuristics?.should_not be_true
    # end
    # it "should deal with comments having url/email independently of their word-count" do
    #   Tester.new('bye comment bad@wrong.com', User.new, Comment).pass_ham_heuristics?.should be_true
    # end
    # it "should deal with comments having more than LOWER_WORDS_LIMIT_FOR_COMMENTS words" do
    #   Tester.new_with_random_text(LOWER_WORDS_LIMIT_FOR_COMMENTS+1).pass_ham_heuristics?.should be_true
    # end
    # it "shouldn't deal with Posts having no url/email and less than LOWER_WORDS_LIMIT_FOR_POSTS words" do
    #   Tester.new('That is an example of a post that should not be dealt with by us', User.new, Post).pass_ham_heuristics?.should_not be_true
    # end
    # it "should deal with Posts having a url/email independently of their word-count" do
    #   Tester.new('bye post bad@wrong.com', User.new, Post).pass_ham_heuristics?.should be_true
    # end
    # it "should throw ArgumentError if given unexpected @spammable_class argument" do
    #   lambda{
    #     Tester.new('anything', User.new, 'Posttt').pass_ham_heuristics?
    #   }.should raise_error(ArgumentError)
    # end
    #
    # it "should say DUNNO for items, which have words but none of these words has been seen by the filter" do
    #   Tester.new_with_random_text(LOWER_WORDS_LIMIT_FOR_COMMENTS+1, 10).classify.should == 0
    # end
  end

  describe "#known_words" do
    it "should return an array of words for which the classifier had been given examples in the category" do
      a = Tester.new('this new word')
      a.known_words(:spam).should == ['this']
      a.classify_as!(:spam)
      a.known_words(:spam).should == a.words
    end
    it "known_words + new_words = words" do
      a = Tester.new('this new word')
      (a.known_words(:spam) + a.new_words(:spam)).should == a.words
    end
  end

  describe "extreme cases" do
    it "should fallback to training_examples_with_feature::any if there're no examples in the database for a particular feature" do
      # a new feature should be added with no examples and make sure the classifier won't break
      pending('todo')
    end
    it "throw an exception if no training examples were given, but it's asked for classification" do
      # if SpamClassificationIndex.count(:spam) or SpamClassificationIndex.count(:ham) is 0.0 => throw an exception
      pending('todo')
    end
  end

  describe "#feature_present?" do
    it "should throw NoMethodError if a feature look-up method has not been implemented" do
      pending('')
    end
  end
end
