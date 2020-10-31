function [obj ,transformation ]=fitSVMPosterior (obj ,varargin )






















































































ifnargin >1 
[varargin {:}]=convertStringsToChars (varargin {:}); 
end
internal .stats .checkNotTall (upper (mfilename ),0 ,obj ,varargin {:}); 

ifisa (obj ,'classreg.learning.classif.CompactClassificationSVM' )

obj =checkScoreTransform (obj ); 

ifisa (obj ,'ClassificationSVM' )&&...
    (isempty (varargin )||ischar (varargin {1 }))
cv =crossval (obj ,varargin {:}); 
Y =cv .Y ; 
classnames =classreg .learning .internal .ClassLabel (cv .ClassNames ); 
prior =cv .Prior ; 
[~,s ]=kfoldPredict (cv ); 
clear cv ; 
else
ifnumel (varargin )<1 ||(numel (varargin )==1 &&~istable (varargin {1 }))
error (message ('stats:fitSVMPosterior:PassXYtoCompactObject' )); 
end
X =varargin {1 }; 
[Y ,extraArgs ]=classreg .learning .internal .inferResponse (obj .ResponseName ,X ,varargin {2 :end}); 

Y =classreg .learning .internal .ClassLabel (Y ); 

ifnumel (Y )~=size (X ,1 )
error (message ('stats:fitSVMPosterior:XandYSizeMismatch' )); 
end

ifnumel (levels (Y ))>2 
error (message ('stats:fitSVMPosterior:TooManyLevelsInY' )); 
end

classnames =obj .ClassSummary .ClassNames ; 
prior =obj .Prior ; 
[~,s ]=predict (obj ,X ,extraArgs {:}); 
end

elseifisa (obj ,'classreg.learning.partition.ClassificationPartitionedModel' )...
    &&numel (obj .Trained )>0 ...
    &&isa (obj .Trained {1 },'classreg.learning.classif.CompactClassificationSVM' )

obj =checkScoreTransform (obj ); 

if~isempty (varargin )
error (message ('stats:fitSVMPosterior:DoNotPassOptionalParamsToCrossValidatedObject' )); 
end

Y =obj .Y ; 
classnames =classreg .learning .internal .ClassLabel (obj .ClassNames ); 
prior =obj .Prior ; 
[~,s ]=kfoldPredict (obj ); 
else
error (message ('stats:fitSVMPosterior:BadObjectType' )); 
end

ifnumel (classnames )~=2 
error (message ('stats:fitSVMPosterior:ClassNamesMustHaveTwoElements' )); 
end

s =s (:,2 ); 

Y =classreg .learning .internal .ClassLabel (Y ); 
y =grp2idx (Y ,classnames )-1 ; 

ifall (isnan (s ))
error (message ('stats:fitSVMPosterior:AllScoresAreNaNs' )); 
end


ifsum (y ==1 )==0 
transformation .Type ='constant' ; 
transformation .PredictedClass =labels (classnames (1 )); 
obj .ScoreTransform =eval (sprintf ('@(S)constant(S,%i)' ,1 )); 
obj .ScoreType ='probability' ; 
return ; 
end


ifsum (y ==0 )==0 
transformation .Type ='constant' ; 
transformation .PredictedClass =labels (classnames (2 )); 
obj .ScoreTransform =eval (sprintf ('@(S)constant(S,%i)' ,2 )); 
obj .ScoreType ='probability' ; 
return ; 
end

smax0 =max (s (y ==0 )); 
smin1 =min (s (y ==1 )); 

ifsmax0 <=smin1 
warning (message ('stats:fitSVMPosterior:PerfectSeparation' )); 
transformation .Type ='step' ; 
transformation .LowerBound =smax0 ; 
transformation .UpperBound =smin1 ; 
transformation .PositiveClassProbability =prior (2 ); 
f =eval (sprintf ('@(S)step(S,%e,%e,%e)' ,smax0 ,smin1 ,prior (2 ))); 
else
coeff =glmfit (s ,y ,'binomial' ,'link' ,'logit' ); 
a =-coeff (2 ); 
b =-coeff (1 ); 
transformation .Type ='sigmoid' ; 
transformation .Slope =a ; 
transformation .Intercept =b ; 
f =eval (sprintf ('@(S)sigmoid(S,%e,%e)' ,a ,b )); 
end

obj .ScoreTransform =f ; 
obj .ScoreType ='probability' ; 

end

function out =constant (in ,cls )%#ok<DEFNU> 
out =zeros (size (in )); 
out (:,cls )=1 ; 
end

function out =sigmoid (in ,a ,b )%#ok<DEFNU> 
out =zeros (size (in )); 
out (:,2 )=1 ./(1 +exp (a *in (:,2 )+b )); 
out (:,1 )=1 -out (:,2 ); 
end

function out =step (in ,lo ,hi ,p )%#ok<DEFNU> 
out =zeros (size (in )); 
s =in (:,2 ); 
out (s >hi ,2 )=1 ; 
out (s <lo ,1 )=1 ; 
between =s >=lo &s <=hi ; 
out (between ,2 )=p ; 
out (between ,1 )=1 -p ; 
end

function obj =checkScoreTransform (obj )
if~strcmp (obj .ScoreTransform ,'none' )
warning (message ('stats:fitSVMPosterior:ResetScoreTransform' )); 
obj .ScoreTransform ='none' ; 
end
end
