classdef Rotor < handle
    % ROTOR Rotor geometry and position.
    %   This class stores the geometric aspects of the rotor. It describes the physical object at
    %   rest and does not consider its operating conditions nor its performance. The class also
    %   references the handle of the Blade object that is used to represent the blade discratization
    %   into multiple elements.
    %
    % Notes:
    %  Almost all properties are private to prevent accidental overwriting. They are either set
    %  during the construction of the object, or through ad-hoc methods.
    % -----
    %
    % Rotor properties:
    %   name     - Rotor name (not used)
    %   nBlades  - Number of blades, [-]
    %   position - Rotor hub position, [m]
    %   Bl       - Blade discretization for the current rotor, (Blade)
    %   Af       - Airfoils used for the current rotor, (Airfoil)
    %   solidity - Rotor solidity, [-]
    %   cutout   - Rotor root cutout, [m]
    %   radius   - Rotor radius, [m]
    %   r0       - Non-dimensionalized root cutout, [-]
    %
    % Rotor methods:
    %   Rotor     - Constructor
    %   plot      - Plots the rotor in 3D
    %   plotblade - Plots a single blade in 3D
    %
    % Rotor constructor:
    %   Rot = Rotor() creates an empty object.
    %
    %   Rot = Rotor(nBlades, rad, chord, twist, iAf, nElem) creates a Rotor object based on the
    %   input provided (see list below). Passing the number of elements during the construction
    %   allows for the automatic discretization of the Rotor into its elements.
    %
    %   Rot = Rotor(nBlades, rad, chord, twist, iAf, nElem, name) creates a Rotor object based on
    %   the input provided (see list below). Passing a name as last input, gives the rotor a
    %   specific name (can be useful to differentiate rotors in post-processing).
    %
    % Constructor inputs:
    %   nBlades : Number of blades, [-]
    %   Af      : Airfoil object handle
    %   rad     : Radius of the guide stations, [m] (at least 2 elements (root and tip))
    %   chord   : Chord of the guide stations, [m] (same size as rad)
    %   twist   : Twist of the guide stations, [deg] (same size as rad)
    %   iAf     : Index of the airfoil for the guide stations, [-] (same size as rad)
    %   nElem   : Number of elements, [-]
    %   name    : (optional) Name of the rotor
    %
    % See also: rotare, template, Blade, af_tools.Airfoil.
    %
    % <a href="https://gitlab.uliege.be/rotare/documentation">Complete documentation (online)</a>

    % ----------------------------------------------------------------------------------------------
    % TODO: Verify solidity calculation.
    % ----------------------------------------------------------------------------------------------
    % (c) Copyright 2022-2023 University of Liege
    % Author: Thomas Lambert <t.lambert@uliege.be>
    % ULiege - Aeroelasticity and Experimental Aerodynamics
    % MIT License
    % Repo: https://gitlab.uliege.be/rotare/rotare
    % Docs: https://gitlab.uliege.be/rotare/documentation
    % Issues: https://gitlab.uliege.be/rotare/rotare/-/issues
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Generic properties
    properties
        name (1, :) {char, string} = 'Unnamed' % Rotor name
        pitchRef (1, :) char = 'zerolift'       % Pitch reference line ('zerolift', 'chordline')
        appli (1, :) char = 'helicopter' % Application ('helicopter', 'propeller', 'windturbine')
    end

    % Rotor geometric properties and reference to other objects handle
    properties (SetAccess = private)

        nBlades (1, 1) double {mustBePositive} = 2 % Number of blades, [-]
        position (1, 3) double = [0, 0, 0] % Rotor center position, [m]

        Bl (1, 1) Blade % Blade discretization for the current rotor (see help Blade)
        Af % Airfoils used for the current rotor (see help af_tools.Airfoil)

        cutout (1, 1) double  % Rotor root cutout, [m]
        radius (1, 1) double  % Rotor radius, [m]
        r0 (1, 1) double {mustBeNonnegative} % Non-dimensionalized root cutout,[-]

    end

    % Properties that depend on other values, calculated on-the-fly
    properties (Dependent)
        solidity (1, 1) double {mustBePositive}  % Rotor solidity, [-]
    end

    methods

        function self = Rotor(nBlades, Af, rad, chord, twist, iAf, nElem, position, name)
            % ROTOR Constructor.
            %   Constructs the object, stores the handle of the airfoil used and creates the blade
            %   object to represent the elements. See main class help for details.
            % Note: Angles should be passed IN DEGREE.

            if nargin > 0
                self.nBlades = nBlades;
                if nargin >= 8
                    self.position = position;
                end
                if nargin == 9
                    self.name = name;
                end

                % Set rotor radius and cutout
                self.radius = rad(end);
                self.cutout = rad(1);
                self.r0 = rad(1) / rad(end);

                % Saves airfoil and create discretization
                self.Af = Af;
                self.Bl = Blade(nBlades, rad, chord, twist, iAf, nElem);
            end
        end

        % ---------------------------------------------
        % Get methods for dependent properties
        function sol = get.solidity(self)
            % [FIXME]: Solidity definition is unclear in formulas

            % Proper definition in theory
            % sol = self.nBlades * sum(self.Bl.area) / pi / (self.radius^2 - self.cutout^2);

            % Hybrid between local and global solidity equals to the simplified one if no taper.
            % This seems to be the one used by Leishman and Stahlhut
            sol = self.nBlades .* self.Bl.chord / pi / self.radius;
        end

        % ---------------------------------------------
        % Other methods
        plot(self, varargin) % 3D plot of the rotor
        plotblade(self, pitch, nSec, varargin) % Plot the blade

    end
end
