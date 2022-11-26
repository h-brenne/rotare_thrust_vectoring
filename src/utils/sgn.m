function signum = sgn(in, zeroVal)
    % SGN Signum function with the possibility to change the value in 0
    %   In theory, the signum function (as implemented with 'sign' in MATLAB) returns 1 for a
    %   positive number, -1 for a negative number and 0 for 0. The SGN function allows the user to
    %   set a custom value for the signum of 0 instead of returning 0 (typically 1).
    %
    %   This tweak is a necessecity for the implementation of the Stahlhut solver. Indeed, in the
    %   explanation of the method for the hovering case, Stahlhut suggests to first study the sign
    %   of the g(phi) function in 0. However, as this function uses a sign(phi), its value should
    %   always be 0 in phi=0.
    %   We beleive that this is a small oversight in the description of the method and therefore the
    %   signum should not cancel in 0, but be equal to 1.
    % -----
    %
    % Syntax:
    %   signum = sgn(in) Normal signum function, returns 0 for 0
    %
    %   signum = sgn(in, zeroVal) Modified signum, returns `zeroVal` when evaluated in 0
    %
    % Inputs:
    %   in      : Array of values to take the signum of
    %   zeroVal : Value to return for sgn(0)
    %
    % Outputs:
    %   signum  : Signum of the input array, where `zeroVal` is returned for inputs = 0;
    %
    % See also: rotare, stahlhut.
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

    % Defaults and constants
    DEFAULT_ZERO = 0;

    % If no zeroVal provided, set it to 0 (default to normal signum function)
    if nargin == 1
        zeroVal = DEFAULT_ZERO;
    end

    % Validate attributes
    validateattributes(in, {'numeric'}, {'nonempty'}, mfilename(), 'in', 1);
    validateattributes(zeroVal, {'numeric'}, {'scalar'}, mfilename(), 'zeroVal', 2);

    % Signum calculation
    % -------------------------------------------
    signum = sign(in);
    signum(signum == 0) = zeroVal; % Replace the zeros by zeroVal

end
