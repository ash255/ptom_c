function [varargout ]=fitclinear (X ,y ,varargin )






















































































































































ifnargin >1 
y =convertStringsToChars (y ); 
end

ifnargin >2 
[varargin {:}]=convertStringsToChars (varargin {:}); 
end

[IsOptimizing ,RemainingArgs ]=classreg .learning .paramoptim .parseOptimizationArgs (varargin ); 
ifIsOptimizing 
[varargout {1 :nargout }]=classreg .learning .paramoptim .fitoptimizing ('fitclinear' ,X ,y ,varargin {:}); 
else
[varargout {1 :nargout }]=ClassificationLinear .fit (X ,y ,RemainingArgs {:}); 
end
end