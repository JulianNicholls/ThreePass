require_relative '../compiler'

describe Compiler do

  before do
    @compiler = Compiler.new
  end

  describe "#pass1" do
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
end
