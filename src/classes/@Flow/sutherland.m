function dynVisc = sutherland(temp)
    % SUTHERLAND Sutherland's law for dynamic viscosity.
    %   Determine the dynamic viscosity of ideal air using only the temperature, by application of
    %   Sutherland's law .
    % -----
    %
    % Syntax:
    %   dynVisc = Flow.sutherland() Calculates the dynamic viscosity of the flow using directly the
    %   value of the 'Flow.temp' property.
    %   dynVisc = Flow.sutherland(temp) Calculates the dynamic viscosity of a flow at a given
    %   temperature 'temp'.
    %
    % Inputs:
    %   temp : fluid temperature, [K]
    %
    % Outputs:
    %   dynVisc : Dynamic viscosity, [kg/(m.s)]
    %
    % Examples:
    %   mu = Flow.sutherland()
    %   mu = Flow.sutherland(300)
    %
    % See also: rotare, Flow.
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

    % Constants and defaults
    REF_TEMP = 273.15;      % Reference temperature, [K]
    REF_VISC = 1.716e-5;    % Reference viscosity, [kg/m.s]
    S_TEMP = 110.4;         % Sutherland temperature, [K]

    validateattributes(temp, {'double'}, {'nonnegative'}, mfilename(), 'temp');

    % Sutherland's law
    dynVisc = REF_VISC * (temp / REF_TEMP).^(3 / 2) .* (REF_TEMP + S_TEMP) ./ (temp + S_TEMP);

end
