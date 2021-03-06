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
  end
  
    
  describe "#pass2" do
    it "should simplify a constant addition" do
      @compiler.pass1 '[ x ] (9 + 9) * x'
      @compiler.pass2
      expect( @compiler.ast ).to eq( {op: '*', a: {op: :imm, n: 18}, b: {op: :arg, n: 0}} );
    end
  
    it "should simplify a constant subtraction" do
      @compiler.pass1 '[ x ] (200 - 99) * x'
      @compiler.pass2
      expect( @compiler.ast ).to eq( {op: '*', a: {op: :imm, n: 101}, b: {op: :arg, n: 0}} );
    end
  
    it "should simplify a constant multiplication" do
      @compiler.pass1 '[ x ] 9 * 9 * x'
      @compiler.pass2
      expect( @compiler.ast ).to eq( {op: '*', a: {op: :imm, n: 81}, b: {op: :arg, n: 0}} );
    end
  
    it "should simplify a constant division" do
      @compiler.pass1 '[ x ] 121 / 11 * x'
      @compiler.pass2
      expect( @compiler.ast ).to eq( {op: '*', a: {op: :imm, n: 11}, b: {op: :arg, n: 0}} );
    end
  
    it "should simplify a complicated expressions" do
      @compiler.pass1 '[ x y z ] ( 2*3*x + 5*y - 3*z ) / (1 + 3 + 2*2)'
      @compiler.pass2
      expect( @compiler.ast ).to eq( 
        {op: "/", 
          a: {op: "-", 
                a: {op: "+", a: { op: "*", a: {op: :imm, n: 6}, b: {op: :arg, n: 0}},
                             b: { op: "*", a: {op: :imm, n: 5}, b: {op: :arg, n: 1}}},
                b: {op: "*", a: {op: :imm, n: 3}, b: {op: :arg, n: 2}}},
          b: {op: :imm, n: 8}
        } )
    
    end
  end
  
  
  describe "#pass3" do
    it "should generate correct code for a simple program" do
      @compiler.pass1 '[ x ] (9 + 9) * x'
      @compiler.pass2
      @compiler.pass3
      expect( @compiler.assembler ).to eq ['LD.M 0', 'SWAP', 'LD.I 18', 'MUL']
    end
    
    it "should generate correct code for a more involved program" do
      @compiler.pass1 '[ x y z ] ( 2*3*x + 5*y - 3*z ) / (1 + 3 + 2*2)'
      @compiler.pass2
      @compiler.pass3
      expect( @compiler.assembler ).to eq ["LD.M 0", "SWAP", "LD.I 6", "MUL", "PUSH", "LD.M 1", "SWAP", "LD.I 5", "MUL", "SWAP", "POP", "ADD", "PUSH", "LD.M 2", "SWAP", "LD.I 3", "MUL", "SWAP", "POP", "SUB", "PUSH", "LD.I 8", "SWAP", "POP", "DIV"]
    end
  end

  describe "#compile" do
    it "should perform passes 1, 2, and 3 in order" do
      @compiler.compile '[ x y z ] ( 2*3*x + 5*y - 3*z ) / (1 + 3 + 2*2)'
      expect( @compiler.assembler ).to eq ["LD.M 0", "SWAP", "LD.I 6", "MUL", "PUSH", "LD.M 1", "SWAP", "LD.I 5", "MUL", "SWAP", "POP", "ADD", "PUSH", "LD.M 2", "SWAP", "LD.I 3", "MUL", "SWAP", "POP", "SUB", "PUSH", "LD.I 8", "SWAP", "POP", "DIV"]
    end
  end
end
