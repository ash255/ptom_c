function obj =fitcsvm (X ,Y ,varargin )












































































































































































































































































































internal .stats .checkNotTall (upper (mfilename ),0 ,X ,Y ,varargin {:}); 

ifnargin >1 
Y =convertStringsToChars (Y ); 
end

ifnargin >2 
[varargin {:}]=convertStringsToChars (varargin {:}); 
end

[IsOptimizing ,RemainingArgs ]=classreg .learning .paramoptim .parseOptimizationArgs (varargin ); 
ifIsOptimizing 
obj =classreg .learning .paramoptim .fitoptimizing ('fitcsvm' ,X ,Y ,varargin {:}); 
else
obj =ClassificationSVM .fit (X ,Y ,RemainingArgs {:}); 
end
end
