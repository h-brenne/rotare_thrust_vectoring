classdef Blade < handle
    % BLADE Blade Element geometric parameters.
    %   This class defines the geometric properties of the blade elements. Most properties are
    %   vectors whose size is equal to the number of elements on the blade. Therefore, a single
    %   instance of this class represents the complete blade discretization.
    %
    % Notes:
    %   - Almost all properties are private to prevent accidental overwriting.
    %
    % Important implementation detail:
    %   The properties of an element correspond to the values at the mid-point of said element. For
    %   instance, if the blade is divided in 2 elements, the first element [0 - 50%] will be placed
    %   at 25% radius and the second one [50% - 100%] will be at 75% radius. The element angles,
    %   velocities, Reynolds, etc will therefore be the ones at 25% and 75% radius.
    %   It is thus perfectly normal to have the first element a little bit after the cutout and the
    %   last one a little bit before the rotor actual radius.
    %   This more rigorous nomenclature has obviously no big impact as long as the total number of
    %   elements is large enough.
    % -----
    %
    % Blade properties:
    %   nElem - Number of elements, [-]
    %   dy    - Element span, [m]
    %   y     - Element absolute radial position, [m]
    %   r     - Element relative radial position (relative to the total radius), [-]
    %   area  - Element area, [m^2]
    %   chord - Element chord, [m]
    %   twist - Element twist (also called stagger angle), [rad]
    %   iAf   - Index of airfoil to use for each element, [-]
    %   sol   - Element solidity, [-]
    %
    % Blade methods:
    %
    % Blade constructor:
    %   Bl = Blade() creates an empty object.
    %
    %   Bl = Blade(nBlades, rad, chord, twist, iAf, nElem) creates a Blade object based on the input
    %   provided (see list below).
    %
    % Constructor inputs:
    %   nBlades : Number of blades, [-]
    %   rad     : Radius of the guide stations, [m] (at least 2 elements (root and tip))
    %   chord   : Chord of the guide stations, [m] (same size as rad)
    %   twist   : Twist of the guide stations, [deg] (same size as rad)
    %   iAf     : Index of the airfoil for the guide stations, [-] (same size as rad)
    %   nElem   : Number of elements to mesh the whole blade, [-]
    %
    % See also: Rotor, rotare, template, af_tools.Airfoil.
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

    % Base properties of the elements
    properties (SetAccess = private)
        nElem (1, :) double {mustBePositive} = 100 % Number of elements, [-]
        dy (1, 1) double {mustBePositive} = 1 % Element span, [m]
        y (1, :) double {mustBePositive}  % Element absolute radial position, [m]
        r (1, :) double {mustBePositive}  % Element relative radial position, [-]
        area (1, :) double {mustBePositive}  % Element area, [m^2]
        chord (1, :) double {mustBePositive} % Element chord, [m]
        twist (1, :) double {mustBeFinite}   % Element twist (also called stagger angle), [rad]
        iAf (1, :) double {mustBePositive}   % Index of airfoil to use for each element, [-]
    end

    properties (SetAccess = private, Dependent)
        sol (1, :) double {mustBePositive}  % Element solidity, [-]
    end

    % Properties kept just to calculate other useful properties later on
    properties (Access = private, Hidden)
        nBlades (1, :) double {mustBePositive} % Number of blades on the rotor, [-]
    end

    methods

        function self = Blade(nBlades, rad, chord, twist, iAf, nElem)
            % BLADE Constructor.
            %   Discretizes the blade in elements, using a spline interpolation between the base
            %   stations passed as input. See main class help for details.
            % Note: Angles should be passed IN DEGREE.

            INTERP_METHOD = 'spline';

            if nargin > 0

                self.nElem = nElem;
                self.nBlades = nBlades;

                % Determine element radial position
                self.dy = (rad(end) - rad(1)) / nElem;
                self.y = linspace(rad(1) + self.dy / 2, rad(end) - self.dy / 2, nElem);
                self.r = self.y / rad(end);

                % Interpolation for element chord and twist
                self.twist = deg2rad(interp1(rad, twist, self.y, INTERP_METHOD));
                self.chord = interp1(rad, chord, self.y, INTERP_METHOD);

                % Assign airfoil to each element
                for i = 1:length(rad) - 1
                    self.iAf(self.y >= rad(i) & self.y <= rad(i + 1)) = iAf(i);
                end

                % Element area (generic elements considered trapezoids)
                yBounds = linspace(rad(1), rad(end), nElem + 1);
                cBounds = interp1(rad, chord, yBounds, INTERP_METHOD);
                self.area = (cBounds(1:nElem) + cBounds(2:nElem + 1)) .* diff(yBounds) / 2;
            end
        end

        % ---------------------------------------------
        % Get methods for dependent properties
        function sol = get.sol(self)
            sol = self.nBlades .* self.chord ./ (2 * pi * self.y);
        end

    end
end
