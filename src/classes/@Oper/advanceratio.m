function advRatio = advanceratio(self, diam, app)
    % ADVRATIO Returns the advance ratio based on the current conditions and Rotor geometry.
    %
    % Note:
    %   The definition of the advance ratio differs for propellers and for helicopter rotors. See
    %   the documentation for more details.
    % -----
    %
    % Syntax:
    %   j = Oper.advanceratio(self, diam, app)
    %
    % Inputs:
    %   diam : Rotor diameter, [m]
    %   app  : Type of application ('helicopter', 'propeller', 'windturbine')
    %
    % Outputs:
    %   advRatio : Advance ratio, [-]
    %
    % See also: rotare, template, Rotor.
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

    switch app
        case 'propeller'
            advRatio = self.speed / (self.rps * diam);

        case {'helicopter', 'windturbine'}
            advRatio = self.speed / (self.omega * diam / 2);

    end

end
