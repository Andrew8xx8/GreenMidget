# Copyright (c) 2011, SoundCloud Ltd., Nikola Chochkov
class Tester < GreenMidget::Base
  attr_accessor :text

  def initialize(text = '')
    self.text = text
  end

  def words
    super
  end

  def log_ratio
    GreenMidgetRecords.fetch_all(words)
    super
  end
end
