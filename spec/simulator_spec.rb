require_relative '../simulate'

describe "Simulator" do
  before do
    @compiler  = Compiler.new
  end
  
  describe "#initialize" do
    it "should be possible to instantiate a simulator with valid code and arguments" do
      sim = Simulator.new( ["IM 1", "PUSH"], [1, 2, 3] )
    end
    
    it "should reject empty arguments" do
      expect { sim = Simulator.new( ["IM 1", "PUSH"], [] ) }.to raise_error( ArgumentError )
    end

    it "should reject bad arguments" do
      expect { sim = Simulator.new( ["IM 1", "PUSH"], ['a', 2, 3] ) }.to raise_error( ArgumentError )
    end
  end

  describe "#set_code" do
    it "should accept valid code and arguments" do
      sim = Simulator.new( ["IM 1", "PUSH"], [1, 2, 3] )
      sim.set_code( ["IM 1", "PUSH"], [1, 2, 3] )
    end
    
    it "should reject empty arguments" do
      sim = Simulator.new( ["IM 1", "PUSH"], [1, 2, 3] )
      expect { sim.set_code( ["IM 1", "PUSH"], [] ) }.to raise_error( ArgumentError )
    end

    it "should reject bad arguments" do
      sim = Simulator.new( ["IM 1", "PUSH"], [1, 2, 3] )
      expect { sim.set_code( ["IM 1", "PUSH"], ['a', 2, 3] ) }.to raise_error( ArgumentError )
    end
  end

  describe "#run" do
    it "should run a simple program" do
      @compiler.compile '[x y z] (x + y) * z'

      runner = Simulator.new( @compiler.assembler, [2, 3, 4] )
      expect( runner.run ).to eq 20
    end
    
    it "should run a more involved program" do
      @compiler.compile '[ x y z ] ( 2*3*x + 5*y - 2*z ) / (1 + 3 + 2*2)'

      runner = Simulator.new( @compiler.assembler, [8, 4, 2] )
      expect( runner.run ).to eq 8
    end

        it "should run a program with correct precedence" do
      @compiler.compile "[ x y z ] x - y - z + 10 / 5 / 2 - 7 / 1 / 7"

      runner = Simulator.new( @compiler.assembler, [5, 4, 1] )
      expect( runner.run ).to eq 0
    end

  end
end
