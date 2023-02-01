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
    % <a href="https://gitlab.uliege.be/rotare/documentation">Complete documentation (online)</a>

    % ----------------------------------------------------------------------------------------------
    % TODO: Implement coaxial rotors
    % TODO: Implement oblique flows
    % ----------------------------------------------------------------------------------------------
    % (c) Copyright 2022-2023 University of Liege
    % Author: Thomas Lambert <t.lambert@uliege.be>
    % ULiege - Aeroelasticity and Experimental Aerodynamics
    % MIT License
    % Repo: https://gitlab.uliege.be/rotare/rotare
    % Docs: https://gitlab.uliege.be/rotare/documentation
    % Issues: https://gitlab.uliege.be/rotare/rotare/-/issues
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % For each rotor, calculate the external velocity and solve the BEMT equations

    for i = 1:length(OpRot)

        % TODO: Coaxial: Determine proper external velocity to pass to the rotor here

        % Solves BEMT equations for the rotor using the true distribution of external velocity
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
