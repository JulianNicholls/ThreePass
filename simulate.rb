class Simulator

  def initialize( code, args, options = {} )
    @verbose = options[:verbose] || false
    set_code( code, args )
  end
  
  def set_code( code, args )
    @code, @args = code, args
    raise ArgumentError.new( "Arguments must be provided" ) unless @args.length > 0
    raise ArgumentError.new( "Arguments must all be numeric constants" ) unless @args.all? { |n| n.is_a? Fixnum }
    
    pp @code if @verbose
  end
  
  def run
    r0, r1 = 0, 0
    stack  = []
    
    @code.each do |instruct|
      match  = instruct.match( /(LD.I|LD.M)\s+(\d+)/ ) || [0, instruct, 0]
      ins, n = match[1], match[2]
      
      case ins
        when 'LD.I' then r0 = n.to_i
        when 'LD.M' then r0 = @args[n.to_i]
        when 'SWAP' then r0, r1 = r1, r0
        when 'PUSH' then stack.push r0
        when 'POP'  then r0 = stack.pop
        when 'ADD'  then r0 += r1
        when 'SUB'  then r0 -= r1
        when 'MUL'  then r0 *= r1
        when 'DIV'  then r0 /= r1
        
        else
          raise ArgumentError.new( "Unknown: #{ins}" )
      end
    end
    
    r0
  end
  
end