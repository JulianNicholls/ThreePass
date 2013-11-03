class Simulator

  def initialize( code, args, options = {} )
    @verbose = options[:verbose] || false
    set_code( code, args )
  end
  
  def set_code( code, args )
    @code, @args = code, args
    pp @code if @verbose
  end
  
  def run
    r0, r1 = 0, 0
    stack  = [];
    
    @code.each do |instruct|
      match  = instruct.match( /(IM|AR)\s+(\d+)/ ) || [0, instruct, 0]
      ins, n = match[1], match[2];
      
      case ins
        when 'IM' then r0 = n.to_i
        when 'AR' then r0 = @args[n.to_i]
        when 'SW' then r0, r1 = r1, r0
        when 'PU' then stack.push r0
        when 'PO' then r0 = stack.pop
        when 'AD' then r0 += r1
        when 'SU' then r0 -= r1
        when 'MU' then r0 *= r1
        when 'DI' then r0 /= r1
      end
    end
    
    r0
  end
  
end