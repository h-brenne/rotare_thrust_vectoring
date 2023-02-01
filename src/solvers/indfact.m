function indfact(OpRot, Mod)
    % INDFACT Bemt solver typically used for propellers.
    %   This function solves iteratively the BEMT equations formulated in terms of induction factors
    %   a and b.
    %   This formultation is commonly found in the litterature for propellers, butit can be used for
    %   any other application as well.
    %   In its original form, this method is not suited for hovering/idle cases. The equations are
    %   slightly  rewritten here to handle this specific case anyway. See the documentation for more
    %   details.
    %
    % Note:
    %   This function manipulates directly the OpRot object or objects associated to OpRot (such as
    %   OpRot.ElPerf) which are defined as handle classes. This is why it has no explicit output,
    %   but keep in mind that OpRot.ElPerf will be modified anyway.
    %
    % Assumptions:
    %   - No extra assumptions besides the typical ones for the BEMT.
    %
    % Solver process:
    %   1. Calculate velocities and angles
    %   2. Get cl and cd
    %   3. Determine loss factor using calculated inflow angle
    %   4. Solve system to update induction factors
    %   5. Iterate on 1-4 until convergence
    % -----
    %
    % Syntax:
    %   indfact(OpRot, Mod)
    %
    % Inputs:
    %   OpRot : Operating Rotor object
    %   Mod   : Model and numerical parameters
    %
    % Outputs:
    %   No explicit output, <strong>but will update OpRot.ElPerf</strong>
    %
    % See also: rotare, bemt, template, OperRotor, ElemPerf.
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
    INIT_AX_FACT = 0.1; % Intial guess for the axial induction factor a, [-]
    INIT_TG_FACT = 0.01; % Intial guess for the swirl induction factor b, [-]
    INIT_VI = 1; % Initial guess for the axial induced velocity (for when Airspeed=0), [m/s]

    % Abbreviations
    airspeed = OpRot.Op.speed;

    % Initial guesses
    if OpRot.Op.speed ~= 0
        a = INIT_AX_FACT * ones(1, OpRot.Rot.Bl.nElem);
        v_ax = (1 + a) * airspeed;
    else
        v_ax = INIT_VI * ones(1, OpRot.Rot.Bl.nElem);
    end
    b = INIT_TG_FACT * ones(1, OpRot.Rot.Bl.nElem);

    % Solve iteratively
    loopCount = 0;
    converged = false;
    while ~converged && loopCount <= Mod.Num.maxIter
        v_ax_old = v_ax;
        b_old = b;

        % Axial and angular velocities at the blade element
        v_ang = (1 - b) .* OpRot.ElPerf.tgSpeed;
        % [DEBUG]: SQRT(PI) GIVES BETTER MATCH?
        % relVel = sqrt(sqrt(pi)) * sqrt(v_ax.^2 + v_ang.^2);
        relVel = sqrt(v_ax.^2 + v_ang.^2);

        % Angles
        phi = atan2(v_ax, v_ang);  % Inflow angle
        alpha = OpRot.ElPerf.truePitch - phi;  % Angle of attack

        % Get new estimates for the coefficients
        [cl, cd] = OpRot.ElPerf.getclcd(alpha);

        % Calculate loss factor
        lossFact = prandtlloss(OpRot.Rot.nBlades, OpRot.Rot.Bl.r, OpRot.Rot.r0, phi, ...
                               Mod.Ext.losses);
        K_T = 1 - (1 - lossFact) .* cos(phi);
        K_P = 1 - (1 - lossFact) .* sin(phi);

        % Analytical solution to the momentum and blade element equations.
        if airspeed == 0
            v_ax = sqrt(((relVel.^2 * OpRot.Rot.nBlades .* OpRot.Rot.Bl.chord) .* ...
                         (cl .* cos(phi) - cd .* sin(phi))) ./ ...
                        (8 * pi * OpRot.Rot.Bl.y .* K_T));
            b = ((relVel.^2 * OpRot.Rot.nBlades .* OpRot.Rot.Bl.chord) .* ...
                 (cl .* sin(phi) + cd .* cos(phi))) ./ ...
                (8 * pi * OpRot.Rot.Bl.y.^2 .* v_ax .* OpRot.Op.omega .* K_P);
        else
            dummy = ((relVel.^2 * OpRot.Rot.nBlades .* OpRot.Rot.Bl.chord) .* ...
                     (cl .* cos(phi) - cd .* sin(phi))) ./ ...
                (8 * pi * OpRot.Rot.Bl.y .* airspeed.^2 .* K_T);

            a = (-1 + sqrt(1 + 4 .* dummy)) / 2;
            b = ((relVel.^2 * OpRot.Rot.nBlades .* OpRot.Rot.Bl.chord) .* ...
                 (cl .* sin(phi) + cd .* cos(phi))) ./ ...
                (8 * pi * OpRot.Rot.Bl.y.^2 .* airspeed .* (1 + a) .* OpRot.Op.omega .* K_P);
            v_ax = (1 + a) * airspeed;
        end

        % Use relaxation to faciliate convergence of nonlinear system
        v_ax = v_ax_old * (1 - Mod.Num.relax) + v_ax * Mod.Num.relax;
        b = b_old  * (1 - Mod.Num.relax) + b * Mod.Num.relax;

        % Convergence criterions
        axial_converged = isconverged(v_ax, v_ax_old, Mod.Num.convCrit);
        swirl_converged = isconverged(b, b_old, Mod.Num.convCrit);
        converged = axial_converged && swirl_converged;
        if loopCount == Mod.Num.maxIter
            warning('Rotare:Solvers:indfact:NotConverged', ...
                    ['Solution not converged with ''indfact'' solver after reaching the '...
                     'maximum number of iterations (%d iter).\n'], loopCount);
        end
        loopCount = loopCount + 1;

    end

    % Update values in ElemPerf
    OpRot.ElPerf.indVelAx = v_ax - airspeed;
    OpRot.ElPerf.indVelTg = b .* OpRot.ElPerf.tgSpeed;
    OpRot.ElPerf.inflAngle = phi;
    OpRot.ElPerf.alpha = alpha;

end
