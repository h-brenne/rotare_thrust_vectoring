classdef OperRotor < handle
    % OPERROTOR Rotor under operating conditions.
    %   This class encapsulates the base Rotor geometry and the Operating conditions ('Oper'). It
    %   is used to represent completely the Rotor during its operation. Besides storing references
    %   to the geometry and the conditions, it is also used to calculate the condition-dependent
    %   properties such as the tip speed of the rotor, etc.
    %   Lastly, this class also contains a reference to the element performances and methods to
    %   calculate the overall rotor performance.
    % -----
    %
    % OperRotor properties:
    %   Rot         - Rotor geometry
    %   Op          - Current operating conditions
    %   ElPerf      - Performance of the elements (angles, velocities, forces, etc)
    %   tgTipSpeed  - Tangential tip speed, [m/s]
    %   relTipSpeed - Relative tip speed, [m/s]
    %
    % OperRotor methods:
    %   calcperf  - Calculate operating rotor performance
    %   calccoeff - (private) Transform one property into its associated coefficient

    % OperRotor Constructor:
    %   OpRot = OperRotor() creates an empty object.
    %   OpRot = OperRotor(Rot, Op) creates an OperRotor object based on the rotor geometry and the
    %   current operating conditions.
    %
    % Constructor inputs:
    %   Rot  : Rotor geometry
    %   Op   : Current operating conditions
    %
    % See also: rotare, Rotor, Oper.
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

    properties
        upstreamVel (2, :) double % Upstream velocity
    end

    properties (SetAccess = private)
        Rot  (1, 1) Rotor % Rotor geometry
        Op   (1, 1) Oper  % Current operating conditions

        ElPerf (1, 1) ElemPerf % Performance of the elements (angles, velocities, forces, etc)

        thrust (1, 1) double % Rotor thrust, [N]
        torque (1, 1) double  % Rotor torque, [N.m]
        power (1, 1) double  % Rotor power, [W]
        eff (1, 1) double  % Rotor eff, [-]

    end

    properties (Dependent)
        tgTipSpeed (1, 1) double  % Tangential tip speed, [m/s]
        relTipSpeed (1, 1) double % Relative tip speed, [m/s]

        cT (1, 1) double % Rotor thrust coefficient, [-]
        cQ (1, 1) double  % Rotor torque coefficient, [-]
        cP (1, 1) double  % Rotor power coefficient, [-]

        nonDim (1, 2) char % Non-dimensionalization factor ('US', 'EU')
    end

    properties (Access = private, Hidden)
        nonDim_cached (1, 2) char = 'US' % Non-dimensionalization factor ('US', 'EU')
    end
    properties (Hidden)
        cpuTime (1, 1) double % CPU time needed for the computation
    end

    methods

        function self = OperRotor(Rot, Op)
            % OperRotor Constructor.
            %   Instantiate the OperRotor object from Rotor geometry, the operating conditions and
            %   the flow properties. See main class help for details.

            if nargin > 0

                % Save geometry and operating conditions
                self.Rot = Rot;
                self.Op = Op;

                % Instantiate basic operating variables for elements
                self.ElPerf = ElemPerf(Rot, Op);

                % Set default upstream velocity to the freestream velocity
                self.upstreamVel = ones(2, Rot.Bl.nElem) .* [Op.speed; 0];
            end
        end

        % ---------------------------------------------
        % Get methods for dependent properties
        function tgSpeed = get.tgTipSpeed(self)
            tgSpeed = self.Rot.radius * self.Op.omega;
        end

        function relSpeed = get.relTipSpeed(self)
            relSpeed = sqrt(self.tgTipSpeed^2 + self.Op.speed^2);
        end

        function cT = get.cT(self)
            cT = calccoeff(self, 'thrust');
        end

        function cQ = get.cQ(self)
            cQ = calccoeff(self, 'torque');
        end

        function cP = get.cP(self)
            cP = calccoeff(self, 'power');
        end

        function nonDim = get.nonDim(self)
            nonDim = self.nonDim_cached;
        end

        % ---------------------------------------------
        % Set methods for dependent properties
        function set.nonDim(self, val)
            self.nonDim_cached = val;
        end

        % ---------------------------------------------
        % Other methods
        calcperf(self) % Calculate operating rotor performance

    end

    methods (Access = private)
        coeff = calccoeff(self, type) % Transform one property into its associated coefficient
    end
end
