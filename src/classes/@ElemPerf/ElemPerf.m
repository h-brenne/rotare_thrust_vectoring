classdef ElemPerf < handle
    % ELEMPERF Operation-dependant variables for the blade elements.
    %   This class is used to store the operation-dependant variables of the blade elements, such as
    %   the angles, velocities, reynolds, etc. It also implements methods to determine the
    %   aerodynamic loads generated on each element.
    %
    % Notes:
    %   - The geometric parameters of the blade elements is described with the Blade class.
    %   - The properties of this class are vectors whose size is equal to the number of elements on
    %   the blade. Therefore, a single instance of this class represents the complete blade mesh.
    % -----
    %
    % ElemPerf properties:
    %   tgSpeed  - Tangential speed, [m/s]
    %   pitch    - True pitch (twist + collective + offset for zero-lift), [rad]
    %   reynolds - Reynolds number, [-]
    %
    % ElemPerf methods:
    %   ElemPerf   - Constructor
    %   plot       - Plot the evolution of the various properties along the span
    %   calcforces - Calculate forces, torque and power
    %   getclcd    - (private) Get values of cl and cd for all elements
    %
    % ElemPerf constructor:
    %   ElPerf = ElemPerf() creates an empty object.
    %   ElPerf = ElemPerf(Elem, Op, Flow) creates an ElemPerf object based on the input provided
    %   (see list below). By default, the pitch of each element will be the geometric pitch (based
    %   on the chord line of each element).
    %
    % Constructor inputs:
    %   Elem   : Number of elements to mesh the whole blade, [-]
    %   Op     : Rotor object to discretize, (Rotor object)
    %   Flow   : Flow current properties, (Flow object)
    %
    % See also: rotare, template, bemt, Rotor, Elem, Op, Flow.
    %
    % <a href="https:/gitlab.uliege.be/rotare/documentation">Complete documentation (online)</a>

    % ----------------------------------------------------------------------------------------------
    % Implementation:
    %   - alpha is implemented as a dependent property to prevent Matlab complaining when we set cl
    %     and cd along with alpha (possible issues with property initialization order dependency).
    %   - similar logic is used for indVelAx and indVelTg which automatically set their repsective
    %     velocity ratios.
    % ----------------------------------------------------------------------------------------------
    % (c) Copyright 2022-2023 University of Liege
    % Author: Thomas Lambert <t.lambert@uliege.be>
    % ULiege - Aeroelasticity and Experimental Aerodynamics
    % MIT License
    % Repo: https://gitlab.uliege.be/rotare/rotare
    % Docs: https://gitlab.uliege.be/rotare/documentation
    % Issues: https://gitlab.uliege.be/rotare/rotare/-/issues
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    properties (SetAccess = private)
        Rot (1, 1) Rotor % Handle of the rotor linked to this specific ElemPerf instance
        Op (1, 1)  Oper  % Handle of the Operating point linked to this specific ElemPerf instance

        reynolds (1, :) double % Reynolds number, [-]

        tgSpeed   (1, :) double % Tangential speed, [m/s]
        pitch     (1, :) double % Pitch (twist + collective), [rad]
        alpha0    (1, :) double % Zero lift angle of attack, [rad]
        truePitch (1, :) double % Pitch (twist + collective - alpha_0), [rad]

        cl  (1, :) double % Lift coefficient, [-]
        cd  (1, :) double % Drag coefficient, [-]
        dL  (1, :) double % Lift, [N]
        dD  (1, :) double % Drag, [N]
        dT  (1, :) double % Thrust, [N]
        dQ  (1, :) double % Torque, [N.m]
        dPi (1, :) double % Induced power, [W]
        dPp (1, :) double % Profile power, [W]
        dP  (1, :) double % Total power, [W]

    end

    properties
        inflAngle (1, :) double % Inflow angle, [rad]
    end

    % Make alpha a dependent property because Matlab does not like when we set multiple properties
    % from a single set method otherwise.
    properties (Dependent)
        alpha    (1, :) double % Angle of attack, [rad]
        indVelAx (1, :) double % Induced axial velocity at rotor disk, [m/s]
        indVelTg (1, :) double % Induced tangential velocity at rotor disk, [m/s]
        inflowRat (1, :) double % Inflow ratio, [-]
        swirlRat  (1, :) double % Swirl ratio, [-]
        indInflowRat (1, :) double % Induced velocity ratio, [-]
        indSwirlRat  (1, :) double % Induced swirl ratio, [-]
    end

    % Cache for dependent properties to avoid excessive recalculation
    properties (Access = private, Hidden)
        alpha_    (1, :) double % Angle of attack, [rad]
        indVelAx_ (1, :) double % Induced axial velocity at rotor disk, [m/s]
        indVelTg_ (1, :) double % Induced tangential velocity at rotor disk, [m/s]
        inflowRat_ (1, :) double % Inflow ratio, [-]
        swirlRat_  (1, :) double % Swirl ratio, [-]
        indInflowRat_ (1, :) double % Induced velocity ratio, [-]
        indSwirlRat_  (1, :) double % Induced swirl ratio, [-]
    end

    methods

        function self = ElemPerf(Rot, Op)
            % ELEMPERF Constructor.
            %   Instantiates an ElemPerf object and calculates some basic properties using the
            %   element geometry and operating conditions.

            if nargin > 0

                self.Rot = Rot;
                self.Op = Op;

                % Blade pitch
                self.pitch = Rot.Bl.twist + Op.coll;

                % In-plane velocities
                self.tgSpeed = Op.omega .* Rot.Bl.y;

                % Reynolds
                relVel = sqrt(self.tgSpeed.^2 + Op.speed.^2);
                self.reynolds = Flow.reynolds(relVel, Rot.Bl.chord, Op.Flow.mu, Op.Flow.rho);

                % Get alpha_0 from reynolds
                self.alpha0 = zeros(size(self.pitch));
                for i = 1:length(Rot.Af)
                    idx = (Rot.Bl.iAf == i);
                    Pol = Rot.Af(i).Polar;
                    if numel(Pol.reynolds) == 1
                        self.alpha0(idx) = Pol.Zero.aoa;
                    else
                        self.alpha0(idx) = interp1(Pol.reynolds, Pol.Zero.aoa, ...
                                                   self.reynolds(idx), 'linear', 'extrap');
                    end
                end

                % Calculate truePitch
                if strcmp(self.Rot.pitchRef, 'zerolift')
                    self.truePitch = self.pitch - self.alpha0;
                else
                    self.truePitch = self.pitch;
                end

            end
        end

        % ---------------------------------------------
        % Get methods for dependent properties

        function alpha = get.alpha(self)
            alpha = self.alpha_;
        end

        function indVelAx = get.indVelAx(self)
            indVelAx = self.indVelAx_;
        end

        function indVelTg = get.indVelTg(self)
            indVelTg = self.indVelTg_;
        end

        function inflowRat = get.inflowRat(self)
            inflowRat = self.inflowRat_;
        end

        function swirlRat = get.swirlRat(self)
            swirlRat = self.swirlRat_;
        end

        function indInflowRat = get.indInflowRat(self)
            indInflowRat = self.indInflowRat_;
        end

        function indSwirlRat = get.indSwirlRat(self)
            indSwirlRat = self.indSwirlRat_;
        end

        % ---------------------------------------------
        % Set methods for dependent properties

        function set.alpha(self, val)
            % Cache value
            self.alpha_ = val;

            % Calculate cl and cd based on new alpha and cache it
            [self.cl, self.cd] = getclcd(self, val);
        end

        function set.indVelAx(self, val)
            % Cache value
            self.indVelAx_ = val;

            % Calculate inflow ratios
            self.inflowRat_ = (self.Op.speed + val) ./ (self.Op.omega * self.Rot.radius);
            self.indInflowRat_ = val ./ (self.Op.omega * self.Rot.radius);
        end

        function set.indVelTg(self, val)
            % Cache value
            self.indVelTg_ = val;

            % Calculate inflow ratios
            self.swirlRat_ = (self.tgSpeed - val) ./ (self.Op.omega * self.Rot.radius);
            self.indSwirlRat_ = val ./ (self.Op.omega * self.Rot.radius);
        end

        function set.inflowRat(self, val)
            % Cache value
            self.inflowRat_ = val;

            % Calculate induced velocity and ratio
            self.indVelAx_ = val .* self.Op.omega * self.Rot.radius - self.Op.speed;
            self.indInflowRat_ = self.indVelAx_ ./ (self.Op.omega * self.Rot.radius);
        end

        function set.swirlRat(self, val)
            % Cache value
            self.swirlRat_ = val;

            % Calculate induced swirl velocity and ratio
            self.indVelTg_ = self.tgSpeed - val .* (self.Op.omega * self.Rot.radius);
            self.indSwirlRat_ = self.tgSpeed ./ (self.Op.omega * self.Rot.radius) - val;
        end

        function set.indInflowRat(self, val)
            % Cache value
            self.indInflowRat_ = val;

            % Calculate inflow ratios
            self.inflowRat_ = (self.Op.speed) ./ (self.Op.omega * self.Rot.radius) + val;
            self.indVelAx_ = val .* (self.Op.omega * self.Rot.radius);
        end

        function set.indSwirlRat(self, val)
            % Cache value
            self.indSwirlRat_ = val;

            % Calculate inflow ratios
            self.indVelTg_ = val .* (self.Op.omega * self.Rot.radius);
            self.swirlRat_ = self.tgSpeed ./ (self.Op.omega * self.Rot.radius) - val;
        end

        % ---------------------------------------------
        % Other methods
        plot(self, type) % Plot the evolution of the various properties along the span
        calcforces(self) % Calculate forces, torque and power
        [cl, cd] = getclcd(self, aoaVect, reyVect, i) % Get values of cl and cd
        plotveltriangles(self, nTriangles, varargin)
    end

end
