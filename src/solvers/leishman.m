function leishman(OpRot, Mod)
    % LEISHMAN Bemt solver following Leishman linearised equations.
    %   This is the complete solver for the Leishman equations, as described in 'Principles of
    %   Helicopter Aerodynamics'.
    %   See the technical documentation for a detailed description of the method.
    %
    % Note:
    %   This function manipulates directly the OpRot object or objects associated to OpRot (such as
    %   OpRot.ElPerf) which are defined as handle classes. This is why it has no explicit output,
    %   but keep in mind that OpRot.ElPerf will be modified anyway.
    %
    % Assumptions:
    %   - Small angles
    %   - No swirl
    %   - Linear lift coefficient
    %   - cd << cl
    %
    % Solver process:
    %   1. Determine the inflow ratio assuming no losses
    %   2. Determine the loss factor using the calculated inflow
    %   3. Update the inflow ratios to account for the losses
    %   4. Iterate on 2-3 until convergence
    % -----
    %
    % Syntax:
    %   leishman(OpRot, Mod)
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
    % <a href="https://gitlab.uliege.be/thlamb/rotare-doc">Complete documentation (online)</a>

    % ----------------------------------------------------------------------------------------------
    % Ref: Leishman, "Principles of Helicopter Aerodynamics", Cambridge University Press, 2006.
    % ----------------------------------------------------------------------------------------------
    % (c) Copyright 2022 University of Liege
    % Author: Thomas Lambert <t.lambert@uliege.be>
    % ULiege - Aeroelasticity and Experimental Aerodynamics
    % MIT License
    % Repo: https://gitlab.uliege.be/thlamb/rotare
    % Docs: https://gitlab.uliege.be/thlamb/rotare-doc
    % Issues: https://gitlab.uliege.be/thlamb/rotare/-/issues
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Defaults and constants
    INIT_LOSS_FACT = 1;  % First calculation always assumes no losses

    % Leishman method
    % -------------------------------------------

    % Determine Cl slope for each element, based on Reynolds and approximate resulting velocity
    clSlope = getclslope(OpRot.Rot.Af, OpRot.Rot.Bl.iAf, OpRot.ElPerf.reynolds);

    % Get a first idea of the inflow factor assuming no losses
    [lambda, xi, phi, alpha]  = leishmaneq(OpRot, clSlope, INIT_LOSS_FACT);

    % Loop for loss factor until convergence of inflow
    if ~strcmp(Mod.Ext.losses, 'none')
        converged = false;
        loopCount = 1;

        while ~converged
            lambda_old = lambda;

            % Calculate loss factor
            lossFact = prandtlloss(OpRot.Rot.nBlades, OpRot.Rot.Bl.r, OpRot.Rot.r0, ...
                                   phi, Mod.Ext.losses);

            % Update inflow ratio
            [lambda, xi, phi, alpha] = leishmaneq(OpRot, clSlope, lossFact);

            % Convergence criterion on inflow ratio (lambda)
            converged = isconverged(lambda, lambda_old, Mod.Num.convCrit);
            if loopCount == Mod.Num.maxIter
                error('Rotare:Solvers:leishman:NotConverged', ...
                      ['Solution not converged with ''leishman'' solver after reaching the '...
                       'maximum number of iterations for losses calculation (%d iter).\n'], ...
                      loopCount);
            end
            loopCount = loopCount + 1;
        end

    end

    % Update values in ElemPerf
    OpRot.ElPerf.alpha = alpha;
    OpRot.ElPerf.inflAngle = phi;
    OpRot.ElPerf.indVelAx = lambda * OpRot.tgTipSpeed - OpRot.Op.speed;
    OpRot.ElPerf.indVelTg = OpRot.ElPerf.tgSpeed - xi * OpRot.tgTipSpeed;

end

% --------------------------------------------------------------------------------------------------
function [lambda, xi, phi, alpha] = leishmaneq(OpRot, clSlope, lossFact)
    % LEISHMANEQ Determine the axial inflow ratio using the linearised equation from Leishman.
    % (eq 3.131)
    %
    %   lambda : Axial inflow ratio, [-]
    %   xi     : Swirl ratio, [-]
    %   phi    : Inflow angle, [rad]
    %   alpha  : Angle of attack, [rad]

    % Abbreviations
    lambda_c = OpRot.Op.speed / OpRot.tgTipSpeed;
    sol = OpRot.Rot.solidity; % [FIXME], normally it should be local solidity (see Carroll)
    r = OpRot.Rot.Bl.r;
    pitch = OpRot.ElPerf.truePitch;
    tgSpeed = OpRot.ElPerf.tgSpeed;

    % Formula for 'Lambda' (axial inflow ratio)
    lambda = sqrt(((sol .* clSlope) ./ (16 * lossFact) - lambda_c / 2).^2 + ...
                  (sol .* clSlope .* pitch .* r) ./ (8 * lossFact)) - ...
             ((sol .* clSlope) ./ (16 * lossFact) - lambda_c / 2);

    % Swirl ratio (swirl velocity is neglected: u_i = 0).
    xi = (tgSpeed) ./ OpRot.tgTipSpeed;

    % Inflow angle and local angle of attack
    phi = atan2(lambda, xi);
    alpha = pitch - phi;

end

function clSlope = getclslope(Af, iAf, reynolds)
    % getclslope Determine the lift-curve slope for each element by interpolation.

    clSlope = zeros(size(iAf));

    for i = 1:length(Af)
        clSlope(iAf == i) = interp1(Af(i).Polar.reynolds, ...
                                    Af(i).Polar.Lin.slope, ...
                                    reynolds(iAf == i), ...
                                    'linear', 'extrap');
    end

end
