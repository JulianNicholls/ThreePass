require_relative '../compiler'

class Compiler
  attr_reader :ast
end


describe Compiler do

  before do
    @compiler = Compiler.new
  end

  describe "#pass1" do
    before do
      @argx = {op: :arg, n: "x"}
      @argy = {op: :arg, n: "y"}
      @argz = {op: :arg, n: "z"}
    end
      
    describe "Exceptions" do
      it "should throw an error if there's no program" do
        expect { @compiler.pass1 }.to raise_error( ParseError )
      end
      
      it "should raise an error if the [ is missing" do
        expect { @compiler.pass1 'a b c ] a+b+c' }.to raise_error( ParseError )
      end
      
      it "should raise an error if the ] is missing" do
        expect { @compiler.pass1 '[a b c a+b+c' }.to raise_error( ParseError )
      end
    end
    
    describe "Simple Parsing" do
      it "should parse a simple + operation" do
        @compiler.pass1 '[x y] x + y'
        expect( @compiler.ast ).to eq( {op: "+", a: @argx, b: @argy} )
      end
      
      it "should parse a simple - operation" do
        @compiler.pass1 '[x y] x - y'
        expect( @compiler.ast ).to eq( {op: "-", a: @argx, b: @argy} )
      end
      
      it "should parse a simple * operation" do
        @compiler.pass1 '[x y] x * y'
        expect( @compiler.ast ).to eq( {op: "*", a: @argx, b: @argy} )
      end
      
      it "should parse a simple / operation" do
        @compiler.pass1 '[x y] x / y'
        expect( @compiler.ast ).to eq( {op: "/", a: @argx, b: @argy} )
      end
    end
    
    describe "Left Associativity" do
      it "should work for a x + y + z operation" do
        @compiler.pass1 '[x y z] x + y + z'
        expect( @compiler.ast ).to eq( {:op => "+", :a => {:op => "+", :a => @argx, :b => @argy}, :b => @argz} )
      end
    end
  end
  
end
