require 'spec'
require 'muon/string_stream'
require 'muon/telnet'

module TelnetTestHelpers
  def input(s)
    @stream.input = telnetify(s)
  end

  def output_should_be(expected)
    @stream.output.should == telnetify(expected)
    @stream.output = ''
  end

  def telnetify(s)
    s.gsub(/<([^>]+)>/) do |m|
      Muon::Telnet::Constants.const_get($1).chr
    end
  end
end

describe Muon::Telnet::Stream do
  include TelnetTestHelpers

  before(:each) do
    @stream = Muon::StringStream.new
    @telnet = Muon::Telnet::Stream.new(@stream)
  end

  it 'should get characters' do
    input 'foo'
    'foo'.chars.each do |c|
      @telnet.next.chr.should == c
    end
  end

  it 'should get all available' do
    input 'bar'
    @telnet.next_available.should == 'bar'
  end

  it 'should escape outgoing IAC' do
    @telnet.putc Muon::Telnet::Constants::IAC
    @telnet.putc Muon::Telnet::Constants::IAC.chr
    output_should_be "<IAC><IAC><IAC><IAC>"
  end

  %w{EOR NOP DM BRK IP AO AYT EC EL GA}.each do |name|
    it "should filter out IAC #{name}" do
      input "f<IAC><#{name}>oo"
      @telnet.next_available.should == 'foo'
    end
  end

  %w{DO DONT WILL WONT}.each do |name|
    it "should filter out IAC #{name} <byte>" do
      (0..255).each do |c|
        input "b<IAC><#{name}>#{c.chr}ar"
        @telnet.next_available.should == 'bar'
      end
    end
  end

  it 'should ignore everything between IAC SB and IAC SE' do
    input 'f<IAC><SB>barquux<IAC><SE>oo'
    @telnet.next_available.should == 'foo'
  end

  it 'should remember its state between reads' do
    input 'f<IAC><SB>bar'
    @telnet.next_available.should == 'f'
    input 'quux<IAC><SE>oo'
    @telnet.next_available.should == 'oo'
  end

  it "should have the naive response to IAC DO X" do
    (0..255).each do |c|
      input "<IAC><DO>#{c.chr}"
      @telnet.retrieve_available
      output_should_be "<IAC><WONT>#{c.chr}"
    end
  end

  it "should have the naive response to IAC WILL X" do
    (0..255).each do |c|
      input "<IAC><WILL>#{c.chr}"
      @telnet.retrieve_available
      output_should_be "<IAC><DONT>#{c.chr}"
    end
  end

  def self.q_method_test(command, state, allow, *tests)
    tests.each do |old, new, write|
      test_name = "should go from :#{old} to :#{new} on #{command}"
      test_name += " and write #{write}" if write
      test_name += " when allowed" if allow
      option = 0
      it test_name do
        input "<IAC>#{command}#{option.chr}"
        @telnet.options[option].allow = allow
        @telnet.options[option].send("#{state}=", old)
        @telnet.retrieve_available
        @telnet.options[option].send(state).should == new
        output_should_be "<IAC>#{write}#{option.chr}" unless write.nil?
      end
    end
  end

  # Receive WONT
  q_method_test('<WONT>', 'him', false,
                [:no, :no, nil],
                [:yes, :no, '<DONT>'],
                [:want_no_empty, :no, nil],
                [:want_no_opposite, :want_yes_empty, '<DO>'],
                [:want_yes_empty, :no, nil],
                [:want_yes_opposite, :no, nil])

  # Receive DONT
  q_method_test('<DONT>', 'us', false,
                [:no, :no, nil],
                [:yes, :no, '<WONT>'],
                [:want_no_empty, :no, nil],
                [:want_no_opposite, :want_yes_empty, '<WILL>'],
                [:want_yes_empty, :no, nil],
                [:want_yes_opposite, :no, nil])

  # Received WILL, disallowed
  q_method_test('<WILL>', 'him', false,
                [:no, :no, '<DONT>'],
                [:yes, :yes, nil],
                [:want_no_empty, :no, nil], # error
                [:want_no_opposite, :yes, nil], # error
                [:want_yes_empty, :yes, nil],
                [:want_yes_opposite, :want_no_empty, '<DONT>'])

  # Received DO, disallowed
  q_method_test('<DO>', 'us', false,
                [:no, :no, '<WONT>'],
                [:yes, :yes, nil],
                [:want_no_empty, :no, nil], # error
                [:want_no_opposite, :yes, nil], # error
                [:want_yes_empty, :yes, nil],
                [:want_yes_opposite, :want_no_empty, '<WONT>'])

  # Received WILL, allowed
  q_method_test('<WILL>', 'him', true,
                [:no, :yes, '<DO>'],
                [:yes, :yes, nil],
                [:want_no_empty, :no, nil], # error
                [:want_no_opposite, :yes, nil], # error
                [:want_yes_empty, :yes, nil],
                [:want_yes_opposite, :want_no_empty, '<DONT>'])

  # Received DO, allowed
  q_method_test('<DO>', 'us', true,
                [:no, :yes, '<WILL>'],
                [:yes, :yes, nil],
                [:want_no_empty, :no, nil], # error
                [:want_no_opposite, :yes, nil], # error
                [:want_yes_empty, :yes, nil],
                [:want_yes_opposite, :want_no_empty, '<WONT>'])
end

describe Muon::Telnet::Option do
  include TelnetTestHelpers

  OPT = 0

  before(:each) do
    @stream = Muon::StringStream.new
    @option = Muon::Telnet::Option.new(OPT, @stream)
  end

  it 'should be disabled by default' do
    @option.enabled?.should be_false
  end

  it 'should be disabled if us != :yes' do
    @option.him = :yes
    [:no, :want_no_empty, :want_no_opposite, :want_yes_empty,
     :want_yes_opposite].each do |s|
      @option.us = s
      @option.enabled?.should be_false
    end
  end

  it 'should be disabled if him != :yes' do
    @option.us = :yes
    [:no, :want_no_empty, :want_no_opposite, :want_yes_empty,
     :want_yes_opposite].each do |s|
      @option.him = s
      @option.enabled?.should be_false
    end
  end

  it 'should be enabled if [us,him] == [:yes,:yes]' do
    @option.us = :yes
    @option.him = :yes
    @option.enabled?.should be_true
  end

  it 'should send IAC DO and set him = :want_yes_empty' do
    @option.enable_him
    @option.him.should == :want_yes_empty
    output_should_be "<IAC><DO>#{OPT.chr}"
  end

  it 'should send IAC DONT and set him = :want_no_empty' do
    @option.disable_him
    @option.him.should == :want_no_empty
    output_should_be "<IAC><DONT>#{OPT.chr}"
  end

  it 'should send IAC WILL and set us = :want_yes_empty' do
    @option.enable_us
    @option.us.should == :want_yes_empty
    output_should_be "<IAC><WILL>#{OPT.chr}"
  end

  it 'should send IAC WONT and set us = :want_no_empty' do
    @option.disable_us
    @option.us.should == :want_no_empty
    output_should_be "<IAC><WONT>#{OPT.chr}"
  end
end
