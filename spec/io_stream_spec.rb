require 'spec'
require 'tempfile'
require 'muon/io_stream'

describe Muon::IoStream do
  def tempfile(data = '', &block)
    Tempfile.open('io') do |temp|
      temp.write data
      temp.rewind
      io = IO.for_fd(temp.fileno)
      block.call(io)
    end
  end

  it 'should require an IO object' do
    lambda {Muon::IoStream.new(Object.new)}.should raise_error ArgumentError
  end

  it 'should detect available data' do
    tempfile('foo') do |io|
      stream = Muon::IoStream.new(io)
      stream.data_available?.should be_true
    end
  end

  it 'should read characters' do
    tempfile('foo') do |io|
      stream = Muon::IoStream.new(io)
      stream.next.chr.should == 'f'
      stream.next.chr.should == 'o'
      stream.next.chr.should == 'o'
    end
  end

  it 'should return nil if there is no data available' do
    tempfile('x') do |io|
      stream = Muon::IoStream.new(io)
      stream.next
      stream.data_available?.should be_false
      stream.next.should be_nil
    end
  end
end
