function lme = fitlme(ds,formula,varargin)
%FITLME Create a linear mixed effects model by fitting to data.
%   LME = FITLME(DS,FORMULA) fits a linear mixed effects (LME) model
%   specified by the formula string FORMULA to variables in the dataset/table
%   array DS, and returns the fitted model LME. To illustrate the formula
%   syntax, suppose DS contains a response variable named y, predictor
%   variables named x1, x2,..., xn (continuous or grouping) and grouping
%   variables named g1, g2,..., gR where the grouping variables xi or gi
%   can be categorical, logical, char arrays, or cell arrays of strings.
%
%   The formula string FORMULA specifies the LME model and looks like this:
%
%       'y ~ FIXED + (RANDOM_1 | Grp_1) + ... + (RANDOM_R | Grp_R)'
%
%   where
%
%       FIXED = a specification of the fixed effects design matrix
%
%       Grp_j = a single grouping variable (e.g., g2) or a multiway
%               interaction between grouping variables (e.g., g1:g2:g3)
%
%    RANDOM_j = a specification of the random effects design matrix 
%               corresponding to grouping variable Grp_j
%
%   The response y is modeled as a linear combination of fixed effects,
%   random effects and the observation error term. The symbol '~' is
%   interpreted as "modeled as" and the symbol '|' is interpreted as "by".
%   The specified LME model contains one fixed effect vector for the design
%   matrix generated by FIXED. Rows of the design matrix generated by
%   RANDOM_j get multiplied by a separate random effect vector for every
%   level of grouping variable Grp_j. Random effect vectors induced by
%   (RANDOM_j | Grp_j) are drawn independently from a prior Normal
%   distribution with mean 0 and covariance matrix PSI_j. Random effects
%   for (RANDOM_i | Grp_i) and (RANDOM_j | Grp_j) are independent of each
%   other. The LME model implicitly includes an observation error term
%   whose elements are independent of the random effects and are assumed to
%   be independently drawn from a Normal distribution with mean 0 and
%   constant variance.
%
%   The expressions FIXED, RANDOM_j contain "terms" which are either the
%   symbols x1,...,xn and g1,...,gR (defined as variables in the dataset/table
%   array DS) or their combinations joined by '+' and '-' (e.g., x1 + x2 +
%   x3*x4). Here are the rules for combining terms:
%
%           A + B       term A and term B
%           A - B       term A but without term B
%           A:B         the product of A and B
%           A*B         A + B + A:B
%           A^2         A + A:A
%           ()          grouping of terms
% 
%   The symbol '1' (one) stands for a column of all ones. By default, a
%   column of ones is always included in the design matrix. To exclude a
%   column of ones from the design matrix, explicitly specify '-1' as a
%   term in the expression. 
%
%   The following are some examples of FORMULA term expressions when the
%   predictors are x1, x2 response is y and grouping variables are g1, g2
%   and g3. We will denote an 'Intercept' by the symbol '1' in the examples
%   below.
%
%       'y ~ x1 + x2'         Fixed effects only for 1, x1 and x2.
%
%       'y ~ 1 + x1 + x2'     Fixed effects only for 1, x1 and x2. This
%                             time the presence of intercept is indicated 
%                             explicitly by listing '1' as a predictor in 
%                             the formula.
%
%       'y ~ -1 + x1 + x2'    Fixed effects only for x1 and x2. The
%                             implicit intercept term is suppresed by 
%                             including '-1' in the formula.
%
%       'y ~ 1 + (1 | g1)'    Intercept plus random effect for each level
%                             of the grouping variable g1.
%
%       'y ~ x1 + (1 | g1)'   Random intercept model with a fixed slope
%                             multiplying x1.
%
%       'y ~ x1 + (x1 | g1)'  Random intercepts and slopes, with possible
%                             correlation between them.
%
%       'y ~ x1 + (1 | g1) + (-1 + x1 | g1)' 
%                             Independent random intercepts and slopes.
%
%       'y ~ 1 + (1 | g1) + (1 | g2) + (1 | g1:g2)' 
%                             Random intercept model with independent main
%                             effects for g1 and g2, plus an independent
%                             interaction effect.
%
%   LME = FITLME(...,PARAM1,VAL1,PARAM2,VAL2,...) specifies one or more of
%   the following name/value pairs:
%
%       'CovariancePattern'   
%                         A string/cell array of length R such that element j of
%                         this cell array specifies the pattern of the
%                         covariance matrix of random effect vectors
%                         introduced by (RANDOM_j | Grp_j). Each element of
%                         the cell array for 'CovariancePattern' can either
%                         be a string or a logical matrix. Allowed values
%                         for element j are:
%
%           'FullCholesky'  - a full covariance matrix using the Cholesky 
%                             parameterization (Default). All elements of
%                             the covariance matrix are estimated.
%
%           'Full'          - a full covariance matrix using the 
%                             log-Cholesky parameterization. All elements
%                             of the covariance matrix are estimated.
%
%           'Diagonal'      - a diagonal covariance matrix. Off-diagonal 
%                             elements of the covariance matrix are
%                             constrained to be 0.
%
%           'Isotropic'     - a diagonal covariance with equal variances.
%                             Off-diagonal elements are constrained to be 
%                             0 and diagonal elements are constrained to be
%                             equal.
%
%           'CompSymm'      - a compound symmetry structure i.e., common 
%                             variance along diagonals and equal
%                             correlation between all elements of the
%                             random effect vector.
%
%            PAT            - A square symmetric logical matrix. If 
%                             PAT(a,b) = false then the (a,b) element of
%                             the covariance matrix is constrained to 0.
%
%       'FitMethod'       Specifies the method to use for estimating linear
%                         mixed effects model parameters. Choices are:
%
%           'ML'            - maximum likelihood (Default)
%
%           'REML'          - restricted maximum likelihood
%   
%       'Weights'         Vector of N non-negative weights, where N is the
%                         number of rows in DS. Default is ones(N,1).
%
%       'Exclude'         Vector of integer or logical indices into the 
%                         rows of DS that should be excluded from the fit.
%                         Default is to use all rows.
%
%       'DummyVarCoding'  A string specifying the coding to use for dummy
%                         variables created from categorical variables.
%                         Valid coding schemes are 'reference' (coefficient
%                         for first category set to zero), 'effects'
%                         (coefficients sum to zero) and 'full' (one dummy
%                         variable for each category). Default is
%                         'reference'.
%
%       'Optimizer'       A string specifying the algorithm to use for
%                         optimization. Valid values of this parameter are
%                         'quasinewton' (Default) and 'fminunc'. If
%                         'Optimizer' is 'quasinewton', a trust region
%                         based quasi-Newton optimizer is used. If you have
%                         the Optimization Toolbox, you can also specify
%                         that fminunc be used for optimization by setting
%                         'Optimizer' value to 'fminunc'.
%
%       'OptimizerOptions'
%                         If 'Optimizer' is 'quasinewton', then
%                         'OptimizerOptions' is a structure created by
%                         statset('fitlme'). The quasi-Newton optimizer
%                         uses the following fields:
%
%           'TolFun'        - Relative tolerance on the gradient of the 
%                             objective function. Default is 1e-6.
%                  
%           'TolX'          - Absolute tolerance on the step size.
%                             Default is 1e-12.
%
%           'MaxIter'       - Maximum number of iterations allowed. 
%                             Default is 10000.
%
%           'Display'       - Level of display.  'off', 'iter', or 'final'.
%                             Default is off.
%
%                         If 'Optimizer' is 'fminunc', then 
%                         'OptimizerOptions' is an object set up using 
%                         optimoptions('fminunc'). See the documentation
%                         for optimoptions for a list of all the options
%                         supported by fminunc.
%
%                         If 'OptimizerOptions' is not supplied and
%                         'Optimizer' is 'quasinewton' then the default
%                         options created by statset('fitlme') are used. If
%                         'OptimizerOptions' is not supplied and
%                         'Optimizer' is 'fminunc' then the default options
%                         created by optimoptions('fminunc') are used with
%                         the 'Algorithm' set to 'quasi-newton'.
%
%       'StartMethod'     Method to use to start iterative optimization.
%                         Choices are 'default' (Default) and 'random'. If
%                         'StartMethod' is 'random', a random initial value
%                         is used to start iterative optimization,
%                         otherwise an internally defined default value is
%                         used.
%
%       'Verbose'         Either true or false. If true, then iterative
%                         progress of the optimizer is displayed on screen.
%                         The setting for 'Verbose' overrides field
%                         'Display' in 'OptimizerOptions'. Default is
%                         false.
%
%       'CheckHessian'    Either true or false. If 'CheckHessian' is true
%                         then optimality of the solution is verified by
%                         performing positive definiteness checks on the
%                         Hessian of the objective function with respect to
%                         unconstrained parameters at convergence. Hessian
%                         checks are also performed to determine if the
%                         model is overparameterized in the number of
%                         covariance parameters. Default is false.
%
%   Example: Model gas mileage as a function of car weight, with a random
%            effect due to model year.
%      load carsmall
%      ds = dataset(MPG,Weight,Model_Year);
%      lme = fitlme(ds,'MPG ~ Weight + (1|Model_Year)')
%
%   See also LinearMixedModel, LinearModel, GeneralizedLinearModel, NonLinearModel.

%   Copyright 2012-2017 The MathWorks, Inc. 

    if nargin > 1
        formula = convertStringsToChars(formula);
    end
    
    if nargin > 2
        [varargin{:}] = convertStringsToChars(varargin{:});
    end 

    internal.stats.checkNotTall(upper(mfilename),0,ds,formula,varargin{:});
    
    narginchk(2,Inf);    
    lme = LinearMixedModel.fit(ds,formula,varargin{:});
    
end % end of fitlme.
