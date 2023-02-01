classdef NoseCone < handle
    % NOSECONE Nose cone design equations.
    %   This class is used to calculate the dimensions of a nose cone.
    %   The various cone design and their equations were found on Wikipedia:
    %   https://en.wikipedia.org/wiki/Nose_cone_design
    % Note:
    %   The nose cone designs are only used for the visual representation of the rotor/propeller.
    %   They are just a visual element and have absolutely no impact on the calculation and
    %   numerical results returned by the software.
    % -----
    %
    % NoseCone properties:
    %   type   - Type of cone design. Allowed values are:
    %               'cylinder', 'conic', 'blunted_conic', 'biconic', 'tangent_ogive'
    %               'blunted_tangent_ogive', 'secant_ogive_regular', 'secant_ogive_bulge'
    %               'elliptical', 'parabolic', 'power_series', 'lv_haack', 'vonkarman'
    %   rad    - Cone base radius
    %   len    - Cone total length
    %   rotX   - Rotation around X axis, [deg]
    %   rotY   - Rotation around Y axis, [deg]
    %   rotZ   - Rotation around Z axis, [deg]
    %   offset - Offset (to better adjust blade), [m]
    %   pos    - Base center position, [m]
    %   eq     - Equation for the diameter
    %   coord  - Coordinates for the nose cone
    %
    % NoseCone methods:
    %   NoseCone - Constructor
    %   <type>   - Cone equation for <type>, (see type property for allowed values)
    %   plot     - Plot the nose cone
    %   powerseries - (static) Law for power series
    %   haackcone   - (static) Law for Haack cone
    %   secantogive - (static) Law for secant ogive calculation
    %
    % NoseCone constructor:
    %   Nc = NoseCone() creates an empty object.
    %
    %   Nc = NoseCone(type) creates a NoseCone object with form given by 'type'.
    %
    %   Nc = NoseCone(type, rad) creates a NoseCone with a base radius of 'rad'.
    %
    %   Nc = NoseCone(type, rad, len) creates a NoseCone object with a length of 'len'.
    %
    % Constructor inputs:
    %   type : Type of nose cone geometry, [-]
    %   rad  : Base radius, [m]
    %   len  : Cone length, [m]
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

    % Constants to use as defaults
    properties (Constant, Hidden)
        NB_PTS = 30  % Number of points to define the cone curve
        NB_ROT = 20  % Number of segment for a complete circle

        K_PARABOLIC = 3 / 4  % K' value for the parabolic cone
        N_POWERSERIES = 3 / 4  % n value for the power series
        C_HAAK = 1 / 3  % C value for LV-Haak cone
        BLUNT_FACTOR = 0.25  % Blunted tip radius is 25% of the cone base radius
        SECANT_RHO_BULGE = 0.6  % Factor for rho with respect to tangent ogive definition
        SECANT_RHO_REGULAR = 1.4  % Factor for rho with respect to tangent ogive definition
    end

    properties
        type (1, :) char = 'conic'                % Type of cone design
        rad  (1, 1) double {mustBePositive} = 1   % Cone base radius
        len  (1, 1) double {mustBePositive} = 2.5 % Cone total length
        rotX (1, 1) double {mustBeFinite}   = 0  % Rotation around X axis, [deg]
        rotY (1, 1) double {mustBeFinite}   = 0  % Rotation around Y axis, [deg]
        rotZ (1, 1) double {mustBeFinite}   = 0  % Rotation around Z axis, [deg]
        offset (1, 1) double {mustBeFinite} = 0  % Offset (to better adjust blade), [m]
        pos  (1, 3) double {mustBeFinite}   = [0, 0, 0]  % Base center position, [m]
    end

    properties (Dependent)
        eq (1, 1) double {mustBeFinite}  % Equation for the diameter
        coord (30, 20, 3) double         % Coordinates for the nose cone
    end

    methods

        function self = NoseCone(type, varargin)
            % NoseCone Constructor.
            %   Constructs the NoseCone object by assigning a type and optionally setting its base
            %   radius and total length

            if nargin > 0

                % Determine type of cone
                self.type = type;

                % Set cone dimensions
                if nargin > 1
                    self.rad = varargin{1};
                end
                if nargin > 2
                    self.len = varargin{2};
                end

            end
        end

        % ---------------------------------------------
        % Get methods for dependent properties
        function  eq = get.eq(self)
            eq = self.(self.type)(self.rad, self.len);
        end

        function  coord = get.coord(self)
            % Get cone equation
            y = self.eq(:);
            m = length(y);

            % Angles for revolution
            theta = (0:self.NB_ROT) / self.NB_ROT * 2 * pi;
            sintheta = sin(theta);
            sintheta(self.NB_ROT + 1) = 0;

            % Coordinates
            X = y * cos(theta);
            Y = y * sintheta;
            Z = -(0:m - 1)' / (m - 1) * ones(1, self.NB_ROT + 1); % <0 so cone points upward

            % Scale and offset Z
            Z = Z * self.len + (self.len + self.offset);

            % Rotate the cone
            for i = 1:size(X, 1)
                rotMat = rotx(self.rotX) * roty(self.rotY) * rotz(self.rotZ);
                dummy = rotMat * [X(i, :); Y(i, :); Z(i, :)];
                X(i, :) = dummy(1, :);
                Y(i, :) = dummy(2, :);
                Z(i, :) = dummy(3, :);
            end

            % Shift the cone center
            X = X + self.pos(1);
            Y = Y + self.pos(2);
            Z = Z + self.pos(3);

            % Assign outptut
            coord(:, :, 1) = X;
            coord(:, :, 2) = Y;
            coord(:, :, 3) = Z;

        end

        % ---------------------------------------------
        % Methods to determine the cone equation (can be used with some inputs)
        function y = cylinder(~, rad, ~)
            y = [rad, rad];
        end

        function y = conic(self, rad, len)
            x = linspace(0, len, self.NB_PTS);
            y = self.powerseries(x, len, rad, 1);
        end

        function y = blunted_conic(self, rad, len)
            rn = self.BLUNT_FACTOR * rad;
            xt = len^2 / rad * sqrt(rn^2 / (rad^2 + len^2));
            xcone = linspace(xt, len, 20);
            ycone = xcone * rad / len;

            x0 = xt + sqrt(rn^2 - ycone(1)^2);
            xa = x0 - rn;
            xsphere = linspace(xa, xt, 100);
            ysphere = sqrt(rn^2 - (xsphere - x0).^2);

            xall = [xsphere(1:end - 1), xcone];
            yall = [ysphere(1:end - 1), ycone];
            y = interp1(xall, yall, linspace(xa, len, self.NB_PTS));
        end

        function y = biconic(self, rad, len)
            len1 = 0.3 * len;  % tip
            len2 = len - len1; % base
            rad1 = rad / 2;

            x1 = linspace(0, len1, 10);
            y1 = x1 * rad1 / len1;
            x2 = linspace(len1, len, 10);
            y2 = rad1 + ((x2 - len1) * (rad - rad1)) / len2;

            xall = [x1(1:end - 1), x2];
            yall = [y1(1:end - 1), y2];
            y = interp1(xall, yall, linspace(0, len, self.NB_PTS));
        end

        function y = tangent_ogive(self, rad, len)
            x = linspace(0, len, self.NB_PTS);
            rho = (rad^2 + len^2) / (2 * rad);
            y = sqrt(rho^2 - (len - x).^2) + rad - rho;
        end

        function y = blunted_tangent_ogive(self, rad, len)
            rn = self.BLUNT_FACTOR * rad;

            rho = (rad^2 + len^2) / (2 * rad);

            x0 = len - sqrt((rho - rn)^2 - (rho - rad)^2);
            yt = rn * (rho - rad) / (rho - rn);
            xt = x0 - sqrt(rn^2 - yt^2);
            xa = x0 - rn;

            xcone = linspace(xt, len, 50);
            ycone = sqrt(rho^2 - (len - xcone).^2) + rad - rho;

            xsphere = linspace(xa, xt, 100);
            ysphere = sqrt(rn^2 - (xsphere - x0).^2);

            xall = [xsphere(1:end - 1), xcone];
            yall = [ysphere(1:end - 1), ycone];
            y = interp1(xall, yall, linspace(xa, len, self.NB_PTS));
        end

        function y = secant_ogive_regular(self, rad, len)
            x = linspace(0, len, self.NB_PTS);
            y = self.secantogive(x, len, rad, self.SECANT_RHO_REGULAR);
        end

        function y = secant_ogive_bulge(self, rad, len)
            x = linspace(0, len, self.NB_PTS);
            y = self.secantogive(x, len, rad, self.SECANT_RHO_BULGE);
        end

        function y = elliptical(self, rad, len)
            x = linspace(len, 0, self.NB_PTS);
            y = rad * sqrt(1 - x.^2 / len^2);
        end

        function y = parabolic(self, rad, len)
            x = linspace(0, len, self.NB_PTS);
            y = rad * ((2 * (x / len) - self.K_PARABOLIC * (x / len).^2) / (2 - self.K_PARABOLIC));
        end

        function y = power_series(self, rad, len)
            x = linspace(0, len, self.NB_PTS);
            y = self.powerseries(x, len, rad, self.N_POWERSERIES);
        end

        function y = lv_haack(self, rad, len)
            x = linspace(0, len, self.NB_PTS);
            y = self.haackcone(x, len, rad, self.C_HAAK);
        end

        function y = vonkarman(self, rad, len)
            x = linspace(0, len, self.NB_PTS);
            y = self.haackcone(x, len, rad, 0);
        end

        % -----------------------------------------
        % Other methods
        plot(self, color)  % Plot the cone
    end

    % ---------------------------------------------
    % Static helper methods
    methods (Static, Access = private)

        function y = powerseries(x, len, rad, n)
            % POWERSERIES Power series formula
            y = rad * (x / len).^n;
        end

        function y = haackcone(x, len, rad, cValue)
            % HAACKCONE Haack series formula
            theta = acos(1 - (2 * x) / len);
            y = rad / sqrt(pi) * sqrt(theta - sin(2 * theta) / 2 + cValue * sin(theta).^3);
        end

        function y = secantogive(x, len, rad, rhoFact)
            % SECANTOGIVE Secant ogive formula
            rho = rhoFact * (rad^2 + len^2) / (2 * rad);
            alpha = acos((sqrt(len^2 + rad^2)) / (2 * rho)) - atan(rad / len);
            y = sqrt(rho^2 - (rho * cos(alpha) - x).^2) - rho * sin(alpha);
        end

    end

end
