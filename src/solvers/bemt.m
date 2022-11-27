function bemt(OpRot, Mod)
    % BEMT Solves BEMT equations using the chosen solver.
    %   This is function is at the core of Rotare. It implements different ways to solve the
    %   Blade Element Momentum equations and returns the Rotor object with its performances.
    % Note:
    %   It solves each rotor separately, one at a time. Before solving the BEMT equations for a
    %   Rotor, this function will determine the true external velocity distribution by taking into
    %   account the output flow of the upstream rotor.
    % -----
    %
    % Syntax:
    %   Rot = BEMT(Rot, Mod, Flow)
    %
    % Inputs:
    %   Rot  : Rotor object fully defined
    %   Flow : Flow variables
    %   Mod  : Model and numerical parameters
    %
    % Output:
    %   Rot : Rotor object with calculated performances
    %
    % See also: rotare, leishman, stahlhut, propsolv, turbsolv.
    %
    % <a href="https://gitlab.uliege.be/thlamb/rotare-doc">Complete documentation (online)</a>

    % ----------------------------------------------------------------------------------------------
    % TODO: Implement coaxial rotors
    % TODO: Implement oblique flows
    %   - Edit upstreamVel accordingly
    % ----------------------------------------------------------------------------------------------
    % (c) Copyright 2022 University of Liege
    % Author: Thomas Lambert <t.lambert@uliege.be>
    % ULiege - Aeroelasticity and Experimental Aerodynamics
    % MIT License
    % Repo: https://gitlab.uliege.be/thlamb/rotare
    % Docs: https://gitlab.uliege.be/thlamb/rotare-doc
    % Issues: https://gitlab.uliege.be/thlamb/rotare/-/issues
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % For each rotor, calculate the upstream external velocity and solve the BEMT equations

    bemtsinglerot(OpRot(1), Mod);

    for i = 2:length(OpRot)

        % [FIXME] Not quite correct. Depends on the spacing between the two rotors
        OpRot(i).upstreamVel = OpRot(i).upstreamVel + ...
            [2 * OpRot(i - 1).ElPerf.indVelAx; 2 * OpRot(i - 1).ElPerf.indVelTg];

        bemtsinglerot(OpRot(i), Mod);

    end

end

function bemtsinglerot(OpRot, Mod)
    % BEMTSINGLEROT  Calculates the BEMT for a single rotor.
    %   This core function solves the BEMT equations using the appropriate solver, then calculates
    %   the forces on each element and the overall performance of the rotor.

    % Determine angles, velocities and forces for each element using the proper solver
    solver = str2func(Mod.solver);
    solver(OpRot, Mod);

    % Calculate elemental forces, torque and power
    OpRot.ElPerf.calcforces;

    % Calculate overall rotor performance
    OpRot.calcperf;
end
