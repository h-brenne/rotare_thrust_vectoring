function calcperf(self)
    % CALCPERF Calculate forces, torque and power.
    %   This method integrates the performance results obtained for each element in order to
    %   determine the overall performance of the rotor in term of thrust, torque, power and
    %   efficiency. This is essentially the last step of the Blade Element Momentum Theory.
    % -----
    %
    % Syntax:
    %   OpRot.calcperf() calculates the overall rotor thrust, torque, power and efficiency.
    %
    % Inputs:
    %   None
    %
    % Outputs:
    %    Updates the following properties of the OperRot object:
    %       - thrust : Thrust, [N]
    %       - torque : Torque, [N.m]
    %       - power  : Power, [W]
    %       - eff    : Global efficiency, [-]
    %
    % See also: OperRot, ElemPerf.
    %
    % <a href="https://gitlab.uliege.be/rotare/documentation">Complete documentation (online)</a>

    % ----------------------------------------------------------------------------------------------
    % (c) Copyright 2022-2023 University of Liege
    % Author: Thomas Lambert <t.lambert@uliege.be>
    % ULiege - Aeroelasticity and Experimental Aerodynamics
    % MIT License
    % Repo: https://gitlab.uliege.be/rotare/rotare
    % Docs: https://gitlab.uliege.be/rotare/documentation
    % Issues: https://gitlab.uliege.be/rotare/rotare/-/issues
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Defaults and constants
    INTEGRATION_TYPE = 'trap'; % Integrate using rectangular ('rect') or trapezoidal ('trap') method

    % Thrust, torque and power
    if strcmp(INTEGRATION_TYPE, 'rect')
        self.thrust = sum(self.ElPerf.dT);
        self.torque = sum(self.ElPerf.dQ);
        self.power = sum(self.ElPerf.dP);
    elseif strcmp(INTEGRATION_TYPE, 'trap')
        self.thrust = trapz(self.ElPerf.dT);
        self.torque = trapz(self.ElPerf.dQ);
        self.power = trapz(self.ElPerf.dP);
    end

    self.eff = self.thrust * self.Op.speed ./ self.power;

end
