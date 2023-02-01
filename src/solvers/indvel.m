function indvel(OpRot, Mod)
    % INDVEL Bemt solver typically used for (wind) turbines.
    %   This solver focuses on the iterative resolution for the induced velocities directly instead
    %   of solving for the induction factors. This more rigorous formulation allows to alleviate the
    %   limitations imposed on the 'indfact' solver. In particular, the 'indvel' solvers does not
    %   require special attention for the case of hovering/idle rotors.
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
    %   3. Calculate loss factor using the calculated inflow
    %   4. Determine forces and update velocities
    %   5. Iterate on 1-4 until convergence
    % -----
    %
    % Syntax:
    %   indvel(OpRot, Mod)
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
    % FSOLVE_OPTS = optimoptions('fsolve', 'Display', 'none');

    % DEFAULTS AND CONSTANTS
    vw = ones(1, OpRot.Rot.Bl.nElem) * OpRot.Op.speed + 1; % Axial vel in the slipstream
    uw = zeros(size(vw)); % Tangential vel in the slipstream

    % Solve iteratively
    loopCount = 0;
    converged = false;

    while ~converged && loopCount <= Mod.Num.maxIter

        vw_old = vw;
        uw_old = uw;

        % Compute the velocity components at the propeller disk
        v = (OpRot.Op.speed + vw) / 2;
        u = OpRot.ElPerf.tgSpeed - uw / 2;

        % Local mass flow rate
        dmdot = 2 * pi * OpRot.Op.Flow.rho * OpRot.Rot.Bl.y * OpRot.Rot.Bl.dy .* v;

        % Compute new estimates for the velocity magnitude and flow angle
        relVel = sqrt(v.^2 + u.^2);

        % Angles
        phi = atan2(v, u);  % Inflow angle
        alpha = OpRot.ElPerf.truePitch - phi;

        % Get new estimates for the coefficients
        [cl, cd] = OpRot.ElPerf.getclcd(alpha);

        % Loss factor (separate swirl and axial components)
        lossFact = prandtlloss(OpRot.Rot.nBlades, OpRot.Rot.Bl.r, OpRot.Rot.r0, phi, ...
                               Mod.Ext.losses);
        K_T = 1 - (1 - lossFact) .* cos(phi);
        K_P = 1 - (1 - lossFact) .* sin(phi);

        % Calculate lift and drag on the elements
        dL = coeff2force(cl, OpRot, relVel);
        dD = coeff2force(cd, OpRot, relVel);

        % Thrust and torque contributions
        dFa = dL .* cos(phi) - dD .* sin(phi);
        dFu = dL .* sin(phi) + dD .* cos(phi);

        % Final system to solve for v and u
        vw = OpRot.Op.speed + dFa ./ dmdot ./ K_T;
        uw = dFu ./ dmdot ./ K_P;

        % Use relaxation to faciliate convergence of nonlinear system
        vw = vw_old * (1 - Mod.Num.relax) + vw * Mod.Num.relax;
        uw = uw_old  * (1 - Mod.Num.relax) + uw * Mod.Num.relax;

        % Convergence criterions
        axial_converged = isconverged(vw, vw_old, Mod.Num.convCrit);
        swirl_converged = isconverged(uw, uw_old, Mod.Num.convCrit);
        converged = axial_converged && swirl_converged;
        if loopCount == Mod.Num.maxIter
            warning('Rotare:Solvers:indvel:NotConverged', ...
                    ['Solution not converged with ''indvel'' solver after reaching the '...
                     'maximum number of iterations (%d iter).\n'], loopCount);
        end
        loopCount = loopCount + 1;

    end

    % Update values in ElemPerf
    OpRot.ElPerf.inflAngle = phi;
    OpRot.ElPerf.alpha = alpha;
    OpRot.ElPerf.indVelAx = v - OpRot.Op.speed;
    OpRot.ElPerf.indVelTg = uw / 2;

end

function force = coeff2force(coeff, OpRot, speed)
    % COEFF2FORCE Convert aerodynamic coefficient to force

    rho = OpRot.Op.Flow.rho;
    nondim = OpRot.Rot.nBlades .* (0.5 * rho * OpRot.Rot.Bl.area .* speed.^2);

    force = coeff .* nondim;

end
