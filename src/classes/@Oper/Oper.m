classdef Oper < handle
    % OPER Current operating conditions of the rotor.
    %   This class defines the current operating point of the rotor in terms of altitude, airspeed,
    %   angular velocity and collective pitch setting.
    %   It also contains a reference to the Flow object describing the properties of the external
    %   flow.
    %
    % Notes:
    %   - All properties are set using the constructor to prevent poor instantiation.
    %   - The collective pitch should be in DEG for the input, but will be returned in RAD.
    % -----
    %
    % Oper properties:
    %   alt   - Altitude, [m]
    %   speed - Axial speed, [m/s]
    %   rpm   - Rotor rotation speed, [rpm]
    %   coll  - Rotor collective pitch, [rad]
    %   rps   - Rotor rotation speed, [rps]
    %   omega - Rotor rotation speed, [rad/s]
    %   Flow  - Flow object, describing the external flow properties
    %
    % Oper methods:
    %   advanceratio - Calculate the advance ratio
    %
    % Oper constructor:
    %   Op = Oper(alt, speed, rpm, coll, fluidType) creates the object based on the current
    %   operating conditions passed as input and using the fluidType defined to create the flow
    %   object.
    %
    % Constructor inputs:
    %   alt       : Altitude, [m]
    %   speed     : Axial speed, [m/s]
    %   rpm       : Rotor rotation speed, [rpm]
    %   coll      : Rotor collective pitch, [deg]
    %   fluidType : Fluid type ('air', 'seawater', 'freshwater')
    %
    % See also: rotare, template, Flow, OperRotor.
    %
    % <a href="https://gitlab.uliege.be/rotare/documentation">Complete documentation (online)</a>

    % ----------------------------------------------------------------------------------------------
    % TODO: Add flow angle in Oper conditions for oblique flows.
    % ----------------------------------------------------------------------------------------------
    % (c) Copyright 2022-2023 University of Liege
    % Author: Thomas Lambert <t.lambert@uliege.be>
    % ULiege - Aeroelasticity and Experimental Aerodynamics
    % MIT License
    % Repo: https://gitlab.uliege.be/rotare/rotare
    % Docs: https://gitlab.uliege.be/rotare/documentation
    % Issues: https://gitlab.uliege.be/rotare/rotare/-/issues
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    properties (GetAccess = public, SetAccess = protected)
        alt   (1, 1) double {mustBeNonnegative} % Altitude, [m]
        speed (1, 1) double {mustBeFinite} % Axial speed, [m/s]
        rpm   (:, 1) double {mustBeNonnegative} % Rotor rotation speed, [rpm]
        rps   (:, 1) double {mustBeNonnegative} % Rotor rotation speed, [rps]
        omega (:, 1) double {mustBeNonnegative} % Rotor rotation speed, [rad/s]
        coll  (:, 1) double {mustBeFinite}      % Rotor collective pitch, [rad]
        Flow  (1, 1) Flow % Flow object, describing the external flow properties
        % Optional values:
        tgSpeed   (1, :) double % Tangential speed of blade along sections, [m/s]
        axSpeed   (1, :) double % Axial speed of blade along sections, [m/s]
    end

    methods

        function self = Oper(alt, speed, rpm, coll, fluidType, tgSpeed, axSpeed)
            % Oper Constructor.
            %   Warning: 'coll' must be specified in deg!

            if nargin >= 5
                self.alt = alt;
                self.rpm = rpm;
                self.rps = rpm / 60;
                self.omega = rpm / 60 * (2 * pi);
                self.speed = speed;
                self.coll = deg2rad(coll);
                self.Flow = Flow(fluidType, alt, speed, 0, 0); % TODO: Set angles properly
                self.tgSpeed = [];
                self.axSpeed = [];
            end
            if nargin == 7
                self.tgSpeed = tgSpeed;
                self.axSpeed = axSpeed;
            end
        end

        % ---------------------------------------------
        % Other methods
        advRatio = advanceratio(self, diam, app)

    end

end
