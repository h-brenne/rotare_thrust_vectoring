function re = reynolds(v, l, visc, dens)
    % reynolds Calculate Reynolds number.
    %   This function calculates the flow Reynolds number, based on the flow velocity, the
    %   characteristic length and the flow viscosity.
    %
    % Notes:
    %   1. The function can either work with the kinematic viscosity, or the dynamic viscosity.
    %      If the dynamic viscosity is used, the flow density should be provided as input as well.
    %   2. The function accepts array inputs. In that case, either one parameter is an array and all
    %      the other are scalars, or all elements are arrays of the same size. If all inputs are
    %      arrays, the output Reynolds will be a calculation element-by-element of the array.
    % -----
    %
    % Syntax:
    %   re = Flow.reynolds(v, l, kin_visc)
    %   re = Flow.reynolds(v, l, dyn_visc, dens)
    %
    % Inputs:
    %   v    : Freestream speed magnitude, [m/s]
    %   l    : Characteristic length, [m]
    %   visc : Viscosity (kinematic if only 3 inputs, dynamic if 4 inputs)
    %   dens : (Optional) Freestream density, [kg/m^3]
    %
    % Outputs:
    %   re : Reynolds number, [-]
    %
    % Examples:
    %   re = Flow.reynolds(100, 0.5, 14.88e-6)
    %   re = Flow.reynolds(100, 0.5, 18e-6, 1.25)
    %   re = Flow.reynolds(1:100, 0.5, 14.88e-6)
    %   re = Flow.reynolds([50,100], [0.5, 0.4], [14.88e-6, 14.88e-6])
    %
    % See also: rotare, Flow, Flow.calcreynolds.
    %
    % <a href="https:/gitlab.uliege.be/rotare/documentation">Complete documentation (online)</a>

    % ----------------------------------------------------------------------------------------------
    % (c) Copyright 2022-2023 University of Liege
    % Author: Thomas Lambert <t.lambert@uliege.be>
    % ULiege - Aeroelasticity and Experimental Aerodynamics
    % MIT License
    % Repo: https://gitlab.uliege.be/rotare/rotare
    % Docs: https://gitlab.uliege.be/rotare/documentation
    % Issues: https://gitlab.uliege.be/rotare/rotare/-/issues
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Input validation
    narginchk(3, 4);

    % If no density provided, set it to 1
    % (allows to reuse the same formula for both viscosities)
    if nargin == 3
        dens = 1;
    end

    validateattributes(v, {'double'}, {'nonnegative'}, mfilename(), 'v', 1);
    validateattributes(l, {'double'}, {'nonnegative'}, mfilename(), 'l', 2);
    validateattributes(visc, {'double'}, {'nonempty', 'positive'}, mfilename(), 'visc', 3);
    validateattributes(dens, {'double'}, {'nonempty', 'positive'}, mfilename(), 'dens', 4);

    % Reynolds calculation
    % -------------------------------------------

    % Check if dimensions are compatible and calculate Reynolds
    try
        nu = visc ./ dens;
        re = v .* l ./ nu;

    catch ME
        msg = ['Error for Reynolds.\n' ...
               'If one argument is an array, all the other arguments must either be scalars '...
               'or arrays with the same dimension.'];
        causeException = MException('ROTARE:Flow:reynolds:invalidInput', msg);
        ME = addCause(ME, causeException);
        rethrow(ME);
    end

end
