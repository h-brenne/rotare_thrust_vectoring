function upstreamVel = wakecontraction(freestream, inducedVel, factor)
    % WAKECONTRACTION Calculate velocities after wake contraction for coaxial systems.
    %   As the wake of the first rotor contracts, the velocities impinging on the second
    %   rotor increase. This function is used to determine the proper upstream conditions of the
    %   second rotor in the context of coaxial rotors.
    % -----
    %
    % Syntax:
    %   contractedVel = wakecontraction(previousVel, factor) Calculate the effect of the contraction
    %   factor 'factor' on the velocities of the upstream rotor (combination of 'freestreams' and
    %   inducedvel).
    %
    % Inputs:
    %   freestream : Axial and tangential components of the freestream velocity, [m/s]
    %   inducedVel : Induced velocities for each element at the previous rotor, [m/s]
    %   factor     : Wake contraction factor, [-]
    %
    % Outputs:
    %   upstreamVel : External velocities just upstream of the second rotor, [m/s]
    %
    % Examples:
    %   freestream = [10; 0];
    %   inducedVel = [ElPerf.indVelAx; ElPerf.indVelTg];
    %   upstreamVel = wakecontraction(freestream, inducedVel, sqrt(2)/2)
    %
    % See also: rotare, bemt.
    %
    % <a href="https://gitlab.uliege.be/thlamb/rotare-doc">Complete documentation (online)</a>

    % ----------------------------------------------------------------------------------------------
    % TODO: Verify equations
    % TODO: Factor should be determined based on separation distance between the two rotors
    % ----------------------------------------------------------------------------------------------
    % (c) Copyright 2022 University of Liege
    % Author: Thomas Lambert <t.lambert@uliege.be>
    % ULiege - Aeroelasticity and Experimental Aerodynamics
    % MIT License
    % Repo: https://gitlab.uliege.be/thlamb/rotare
    % Docs: https://gitlab.uliege.be/thlamb/rotare-doc
    % Issues: https://gitlab.uliege.be/thlamb/rotare/-/issues
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Input check
    validateattributes(freestream, {'double'}, ...
                       {'column', 'nonempty'}, ...
                       mfilename(), 'freestream', 1);
    validateattributes(inducedVel, ...
                       {'double'}, {'2d', 'nonempty'}, ...
                       mfilename(), 'inducedVel', 2);
    validateattributes(factor, ...
                       {'double'}, {'scalar', 'nonempty', 'nonzero'}, ...
                       mfilename(), 'factor', 3);

    % Calculation of the upstream velocities
    % -------------------------------------------
    upstreamVel = ones(size(inducedVel)) .* freestream;

    % Adapt values for elements inside the wake of upstream rotor
    radii = ceil(factor * size(inducedVel, 2));
    upstreamVel(1, 1:radii) = upstreamVel(1, 1:radii) + ...
        1 / (2 * factor^2) * inducedVel(1, 1:radii);
    upstreamVel(2, 1:radii) = upstreamVel(2, 1:radii) + ...
        1 / (sqrt(2) * factor) * inducedVel(2, 1:radii);

end
