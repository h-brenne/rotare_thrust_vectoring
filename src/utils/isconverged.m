function bool = isconverged(new, old, convCrit, refVal)
    % isconverged Determine convergence status of a matrix.
    %
    % Note:
    %   This function has two possible ways of operation:
    %       1. abs((new-old)/old) < convCrit
    %       2. abs((new-old)/refVal) < convCrit
    %   In the first example, the convergence is checked as a simple relative change with the value
    %   during the previous step. This can lead to issues if the two values keep changing.
    %   A better way to proceed is to evaluate the relative change with respect to a fixed value.
    %   This generally leads to a faster and more well defined convergence.
    % -----
    %
    % Syntax:
    %   bool = isconverged(new, old, convCrit) Checks if the `new` and `old` values are close enough
    %   (i.e. their relative difference is smaller than the convCrit) to be considered converged.
    %
    %   bool = isconverged(new, old, convCrit, refVal) Checks if the `new` and `old` values are
    %   close enough (i.e. their absolute difference is smaller than the convCrit*refVal) to be
    %   considered converged.
    %
    % Inputs:
    %   new      : New values
    %   old      : Old values
    %   convCrit : Convergence criterion (as the minimum relative error acceptable)
    %   refVal   : (optional) Reference value to use to determine if convergence is reached
    %
    % Outputs:
    %   bool : Logical representing convergence status.
    %
    % Examples:
    %   bool = isconverged(10, 11, 1e-4)
    %   bool = isconverged(rand(3), zeros(3), 1e-4)
    %   bool = isconverged(rand(3), zeros(3), 1e-4, 1)
    %
    % See also: leishman, indfact, indvel.
    %
    % <a href="https://gitlab.uliege.be/thlamb/rotare-doc">Complete documentation (online)</a>

    % ----------------------------------------------------------------------------------------------
    % (c) Copyright 2022 University of Liege
    % Author: Thomas Lambert <t.lambert@uliege.be>
    % ULiege - Aeroelasticity and Experimental Aerodynamics
    % MIT License
    % Repo: https://gitlab.uliege.be/thlamb/rotare
    % Docs: https://gitlab.uliege.be/thlamb/rotare-doc
    % Issues: https://gitlab.uliege.be/thlamb/rotare/-/issues
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Validate inputs
    validateattributes(new, {'numeric'}, ...
                       {'nonempty'}, mfilename(), 'new', 1);
    validateattributes(old, {'numeric'}, ...
                       {'nonempty', 'size', size(new)}, ...
                       mfilename(), 'old', 2);
    validateattributes(convCrit, {'double'}, ...
                       {'scalar', 'positive', 'nonempty', 'nonnan'}, ...
                       mfilename(), 'convCrit', 3);
    if nargin > 3
        validateattributes(refVal, {'double'}, ...
                           {'scalar', 'nonzero', 'nonempty', 'nonnan'}, ...
                           mfilename(), 'refVal', 4);
    else
        refVal = old;
    end

    % Convergence
    % -------------------------------------------
    bool = abs((new - old) ./ refVal) < convCrit; % Relative convergence
    bool = all(bool(:)); % Reduce output to a single boolean value

end
