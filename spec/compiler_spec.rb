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
      @argx = {op: :arg, n: 0}
      @argy = {op: :arg, n: 1}
      @argz = {op: :arg, n: 2}
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
      
      it "should work for a x - y - z operation" do
        @compiler.pass1 '[x y z] x - y - z'
        expect( @compiler.ast ).to eq( {:op => "-", :a => {:op => "-", :a => @argx, :b => @argy}, :b => @argz} )
      end
      
      it "should work for a x * y * z operation" do
        @compiler.pass1 '[x y z] x * y * z'
        expect( @compiler.ast ).to eq( {:op => "*", :a => {:op => "*", :a => @argx, :b => @argy}, :b => @argz} )
      end
      
      it "should work for a x / y / z operation" do
        @compiler.pass1 '[x y z] x / y / z'
        expect( @compiler.ast ).to eq( {:op => "/", :a => {:op => "/", :a => @argx, :b => @argy}, :b => @argz} )
      end
      
      it "should work for a complicated expression" do
        @compiler.pass1 '[ x y z ] ( 2*3*x + 5*y - 3*z ) / (1 + 3 + 2*2)'
        expect( @compiler.ast ).to eq( {op: "/", 
  a: {op: "-", 
        a: {op: "+", 
              a: { op: "*", a: { op: "*", a: {op: :imm, n: 2}, b: {op: :imm, n: 3}
              }, b: {op: :arg, n: 0}
              }, b: { op: "*", a: {op: :imm, n: 5}, b: {op: :arg, n: 1} }
                 }, b: { op: "*", a: {op: :imm, n: 3}, b: {op: :arg, n: 2} }
  }, b: {op: "+", 
          a: { op: "+", a: {op: :imm, n: 1}, b: {op: :imm, n: 3}
          }, b: { op: "*", a: {op: :imm, n: 2}, b: {op: :imm, n: 2} }
    }
} )
      end
    end
    
    describe "#pass2" do
      it "should simplify by folding up constant expressions" do
        @compiler.pass1 '[ x y z ] ( 2*3*x + 5*y - 3*z ) / (1 + 3 + 2*2)'
        @compiler.pass2
        expect( @compiler.ast ).to eq( 
{op: "/", 
  a: {op: "-", 
        a: {op: "+", 
              a: { op: "*", a: {op: :imm, n: 6}, b: {op: :arg, n: 0}
              }, b: { op: "*", a: {op: :imm, n: 5}, b: {op: :arg, n: 1} }
                 }, b: { op: "*", a: {op: :imm, n: 3}, b: {op: :arg, n: 2} }
  }, b: {op: :imm, n: 8}
} )
      
      end
    end
  end
  
end
