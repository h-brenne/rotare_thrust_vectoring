function calcforces(self)
    % CALCFORCES Calculate forces, torque and power.
    %   This method calculates the lift, drag and thrust of all elements, as well as their torque
    %   and (induced, profile and total) power.
    % -----
    %
    % Syntax:
    %   ElPerf.calcforces() calculates all forces, the torque and the power terms for an ElPerf
    %   object.
    %
    % Inputs:
    %   None
    %
    % Outputs:
    %    Updates the following properties of the ElemPerf object:
    %       - dL  : Lift, [N]
    %       - dD  : Drag, [N]
    %       - dT  : Thrust, [N]
    %       - dQ  : Torque, [N.m]
    %       - dPi : Induced power, [W]
    %       - dPp : Profile power, [W]
    %       - dP  : Total power, [W]
    %
    %
    % See also: ElemPerf.
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

    if ~isempty(self.cl)

        axVel = self.Op.speed + self.indVelAx;
        tgVel = self.tgSpeed - self.indVelTg;
        relVel = sqrt(axVel.^2 + tgVel.^2);

        % Non-dimensionalization factor
        nondim = 0.5 .* (self.Op.Flow.rho) .* (relVel).^2 .* (self.Rot.Bl.area);

        % Lift and drag
        self.dL = self.cl .* nondim;
        self.dD = self.cd .* nondim;

        % Thrust, torque and power
        self.dT = self.Rot.nBlades * ...
            (self.dL .* cos(self.inflAngle) - self.dD .* sin(self.inflAngle));
        self.dQ = self.Rot.nBlades * ...
            ((self.dL .* sin(self.inflAngle) + self.dD .* cos(self.inflAngle)) .* self.Rot.Bl.y);

        % Induced, profile and total power requirements of each blade element
        self.dPi = self.Rot.nBlades * (self.dL .* sin(self.inflAngle) .* self.tgSpeed);
        self.dPp = self.Rot.nBlades * (self.dD .* cos(self.inflAngle) .* self.tgSpeed);
        self.dP = self.dPi + self.dPp;
    end
end
