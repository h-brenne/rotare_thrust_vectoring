classdef Flow < handle
    % FLOW Flow properties based on the current operating condition.
    %   This class defines the flow by describing its fluid properties (density, viscosity, etc).
    %   It also describes the general velocity vector of the freesteam, with respect to the rotor
    %   disc.
    %
    % Note:
    %   Most flow properties are dependant on the operating condition of the rotor. It is therefore
    %   important to redefine the object properly for each operating point analyzed.
    % -----
    %
    % Flow properties:
    %   fluid - Fluid type ('air', 'seawater', 'freshwater')
    %   rho   - Fluid Density, [kg/m^3]
    %   temp  - Fluid temperature, [K]
    %   mu    - Fluid dynamic viscosity, [kg/(m.s)]
    %   nu    - Fluid kinematic viscosity, [m^2/s]
    %   speed - External flow total speed, [m/s]
    %   theta - External flow angle w.r.t. rotor disc in the vertical plane, [rad]
    %   phi   - External flow angle w.r.t. rotor disc in the horizontal plane, [rad]
    %
    % Flow methods:
    %   sutherland -  (static) Calculate dynamic viscosity using Sutherland's Law
    %   reynolds   -  (static) Calculate Reynolds number
    %
    % Flow constructor:
    %   Fl = Flow() creates a flow corresponding to air in ISA/SLS conditions.
    %
    %   Fl = Flow(fluid, alt, speed, theta, phi) creates a flow using the appropriate fluid and
    %   calculating its properties based on the altitude (if fluid=air). Sets the flow external
    %   velocity vector using the magnitude and the angles with respect to the rotor plane.
    %
    % Constructor inputs:
    %   fluid : Fluid type ('air', 'seawater', 'freshwater')
    %   alt   : Altitude (only used if fluid='air'), [m]
    %   speed : External flow total speed, [m/s]
    %   theta : External flow angle w.r.t. rotor disc in the vertical plane, [rad]
    %   phi   : External flow angle w.r.t. rotor disc in the horizontal plane, [rad]
    %
    % See also: rotare, template, Blade, af_tools.Airfoil.
    %
    % <a href="https://gitlab.uliege.be/thlamb/rotare-doc">Complete documentation (online)</a>

    % ----------------------------------------------------------------------------------------------
    % TODO: Add flow angle and determine flow components for oblique flows
    % ----------------------------------------------------------------------------------------------
    % (c) Copyright 2022 University of Liege
    % Author: Thomas Lambert <t.lambert@uliege.be>
    % ULiege - Aeroelasticity and Experimental Aerodynamics
    % MIT License
    % Repo: https://gitlab.uliege.be/thlamb/rotare
    % Docs: https://gitlab.uliege.be/thlamb/rotare-doc
    % Issues: https://gitlab.uliege.be/thlamb/rotare/-/issues
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    properties (Constant, Hidden)
        % Air (T_ref = 15°C, P_ref = 101325 Pa)
        AIR_DENS = 1.225   % [kg/m^3]
        AIR_TEMP = 288.15  % [K]

        % Fresh water (T_ref = 15°C)
        FRESHWATER_DENS = 1   % [kg/m^3]
        FRESHWATER_DYNVISC = 0.0011373   % [Pa.s]
        FRESHWATER_TEMP = 288.15  % [K]

        % Sea water (T_ref = 15°C)
        SEAWATER_DENS = 1.02   % [kg/m^3]
        SEAWATER_DYNVISC = 0.00122   % [Pa.s]
        SEAWATER_TEMP = 288.15  % [K]

        BASE_LENGTH = 1  % Used for Reynolds number calculation
    end

    properties (SetAccess = private)
        % fluid - Fluid type ('air', 'seawater', 'freshwater')
        fluid  (1, :) {mustBeMember(fluid, {'air', 'seawater', 'freshwater'})} = 'air'

        rho  (1, 1) double {mustBeNonnegative} % Fluid Density, [kg/m^3]
        temp  (1, 1) double {mustBeNonnegative} % Fluid temperature, [K]
        mu  (1, 1) double {mustBeNonnegative} % Dynamic viscosity [kg/(m.s)]

        % speed - External flow total speed, [m/s]
        speed (1, 1) double {mustBeNonnegative} = 0
        % theta - External flow angle w.r.t. rotor disc in the vertical plane, [rad]
        theta (1, 1) double = 0
        % phi - External flow angle w.r.t. rotor disc in the horizontal plane, [rad]
        phi (1, 1) double = 0
    end

    properties (SetAccess = private, Dependent)
        nu (1, 1) double {mustBeNonnegative} % Fluid kinematic viscosity, [m^2/s]
    end

    methods

        function self = Flow(fluid, alt, speed, theta, phi)
            % Flow Constructor.
            %   Constructs the object using default values, then override them with the inputs if
            %   provided.

            if nargin > 0
                self.fluid = fluid;
            end

            % Set defaults
            switch self.fluid
                case 'freshwater'
                    self.rho = self.FRESHWATER_DENS;
                    self.temp = self.FRESHWATER_TEMP;
                    self.mu = self.FRESHWATER_DYNVISC;
                case 'seawater'
                    self.rho = self.SEAWATER_DENS;
                    self.temp = self.SEAWATER_TEMP;
                    self.mu = self.SEAWATER_DYNVISC;
                case 'air'
                    self.rho = self.AIR_DENS;
                    self.temp = self.AIR_TEMP;
                    self.mu = self.sutherland(self.temp);
            end

            % Update flow properties based on operating conditions
            if nargin > 1

                % Air properties w.r.t. altitude
                if strcmp(self.fluid, 'air')
                    if exist('atmosisa', 'file')
                        [self.temp, ~, ~, self.rho] = atmosisa(alt);
                    else
                        warning('Rotare:Flow:missingAtmosisa', ...
                                ['Function atmosisa not found.\n' ...
                                 'Using properties for air at sea level and 15°C.\n' ...
                                 'For more precise results, you can get the Matlab aerospace ' ...
                                 'toolbox or download an open-source version of that function ' ...
                                 'on: <a href="https://github.com/lentzi90/octave-atmosisa">'...
                                 'https://github.com/lentzi90/octave-atmosisa</a>.\n']);
                    end
                    self.mu = self.sutherland(self.temp);
                end

                % Flow velocity
                self.speed = speed;
                self.theta = theta;
                self.phi = phi;
            end
        end

        % ---------------------------------------------
        % Get methods for dependent properties
        function nu = get.nu(self)
            nu = self.mu / self.rho;
        end

    end

    % -------------------------------------------------
    % Static methods
    methods (Static)

        % Calculate dynamic viscosity using Sutherland's Law
        mu = sutherland(temp)

        % Calculate Reynolds number
        re = reynolds(v, l, visc, dens)

    end

end
