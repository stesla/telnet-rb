require 'spec'
require 'muon/string_stream'

describe Muon::StringStream do
  it 'should detect available data' do
    Muon::StringStream.new('').data_available?.should be_false
    Muon::StringStream.new('x').data_available?.should be_true
  end

  it 'should read characters' do
    string = 'foo'
    stream = Muon::StringStream.new(string)
    string.chars.each do |c|
      stream.next.chr.should == c
    end
  end

  it 'should return nil if there is no data available' do
    Muon::StringStream.new('').next.should be_nil
  end

  it 'should handle output' do
    stream = Muon::StringStream.new('')
    stream.putc 102 # 102.chr == 'f'
    stream.putc 'o'
    stream.print "ob"
    stream.puts "ar"
    stream.output.should == "foobar\n"
  end
end
