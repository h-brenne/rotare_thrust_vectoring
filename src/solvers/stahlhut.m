function stahlhut(OpRot, Mod)
    % STAHLHUT Bemt solver following Stahlhut "one-liner" equation.
    %   This is the complete solver for the Stahlhut equation, as described in 'Aerodynamic design
    %   optimization of proprotors for convertible-rotor concepts'.
    %   See the technical documentation for a detailed description of the method.
    %
    % Note:
    %   This function manipulates directly the OpRot object or objects associated to OpRot (such as
    %   OpRot.ElPerf) which are defined as handle classes. This is why it has no explicit output,
    %   but keep in mind that OpRot.ElPerf will be modified anyway.
    %
    % Assumptions:
    %   No extra assumptions besides the typical ones for the BEMT.
    %
    % Solver process:
    %   1. Loop for each element (fsolve can not work on vectors)
    %   2. Find bounds for fsolve
    %       - If the axial velcity is positive (axial flight/climb): [0, Max]
    %       - If the axial velcity is zero (hover): check value of g(0) and pick the correct root
    %       - If the axial velcity is negative (axial descent): [-Min, 0]
    %      where Min and Max values are calculated based on the available polars.
    %   3. Use fsolve to find the root of g(phi) and calculate the inflow angle, etc from that.
    % -----
    %
    % Syntax:
    %   stahlhut(OpRot, Mod)
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
    % Ref: Stahlhut and Leishman, "Aerodynamic design optimization of proprotors for convertible-
    %      rotor concepts", In American Helicopter Society 68th Annual Forum. Fort Worth, TX, USA.
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
    IND_ANGLE_ZERO = 0; % Zero for the induced angle (need to desingularize)
    IND_ANGLE_UP = pi / 2;   % Upper bound for the induced angle
    IND_ANGLE_LOW = -pi / 2; % Lower bound for the induced angle

    % Stahlhut method
    % -------------------------------------------
    b2phi = zeros(1, OpRot.Rot.Bl.nElem);

    for i = 1:OpRot.Rot.Bl.nElem

        Gfunc = @(phi) stahlhuteq(i, phi, OpRot, Mod.Ext.losses);

        try % If issue with the solver, plot the function and add information to error msg

            % When hover/idle, first evaluate g(0) to determine the sign of g(phi)
            gzero = [];

            if OpRot.Op.speed == 0
                gzero = Gfunc(0);
            end

            % Define interval where the root is expected to be found
            if OpRot.Op.speed > 0 || gzero <= 0
                unk0(1) = IND_ANGLE_ZERO;
                unk0(2) = IND_ANGLE_UP;
            elseif OpRot.Op.speed < 0 || gzero > 0
                unk0(1) = IND_ANGLE_LOW;
                unk0(2) = IND_ANGLE_ZERO;
            end

            % Solve the equation for the current element to find the inflow angle
            [phi, ~] = fzero(Gfunc, unk0);

            % Save inflow angle
            OpRot.ElPerf.inflAngle(i) = phi;
            [~, ~, b2phi(i)] = Gfunc(phi);

        catch ME

            % Plot the function
            allphi = -pi / 2:0.01:pi / 2;
            allg = zeros(size(allphi));
            for j = 1:length(allphi)
                allg(j) = Gfunc(allphi(j));
            end
            plotgfunc(i, allphi, allg, unk0);

            % Return error and information
            msg = sprintf(['Error with Stahlhut solver.\n' ...
                           'MATLAB''s fsolve could not find a solution '...
                           'for the g(phi) equation at element %d when looking for a \n'...
                           'root between %0.2f and %0.2f deg. '...
                           'The g(phi) function has been plotted for that element. '...
                           'Please verify if it should have a zero or not.\n' ...
                           'If the error persists, you may want to tweak the two initial ' ...
                           'bounds for fsolve in the file:\n' ...
                           '<strong>src/solvers/stahlhut.m</strong>.'], i, ...
                          rad2deg(unk0(1)), rad2deg(unk0(2)));
            causeException = MException('Rotare:stahlhut:noSolution', msg);
            ME = addCause(ME, causeException);
            rethrow(ME);
        end

    end

    % Update values in ElemPerf
    OpRot.ElPerf.alpha = OpRot.ElPerf.truePitch - OpRot.ElPerf.inflAngle;

    % Recalculation of the velocities (Eq. 33/34)
    OpRot.ElPerf.swirlRat = OpRot.Rot.Bl.r .* cos(OpRot.ElPerf.inflAngle) ./ b2phi;
    OpRot.ElPerf.inflowRat = OpRot.ElPerf.swirlRat .* tan(OpRot.ElPerf.inflAngle);

end

function [gphi, b1phi, b2phi] = stahlhuteq(i, phi, OpRot, lossType)
    % STAHLHUTEQUATION Equation for g(phi), where phi = inflowAngle (see Eq. 32 in AHS paper).

    % Defaults and constants
    SIGNUM_ZERO = 1; % Value of the signum function in 0;

    % Abbreviations
    r = OpRot.Rot.Bl.r(i); % Relative position
    sol = OpRot.Rot.solidity(i); % Solidity

    reynolds = OpRot.ElPerf.reynolds(i);
    tgSpeed = OpRot.ElPerf.tgSpeed(i);
    pitch = OpRot.ElPerf.truePitch(i);
    airspeed = OpRot.Op.speed;

    % Loss factor (separate swirl and axial components)
    lossFact = prandtlloss(OpRot.Rot.nBlades, r, OpRot.Rot.r0, phi, lossType);
    K_T = 1 - (1 - lossFact) .* cos(phi);
    K_P = 1 - (1 - lossFact) .* sin(phi);

    % Aerodynamic coefficients
    alpha = pitch - phi;
    [cl, cd] = OpRot.ElPerf.getclcd(alpha, reynolds, i);
    gamma = atan(cd / cl);

    % Equation to solve (Eq 32 in Stahlhut paper)
    b1phi = sin(phi) - ...
            1 / (8 * K_T) * sol * 1 / r * cl * sec(gamma) * csc(abs(phi)) * cos(phi + gamma);
    b2phi = cos(phi) + ...
            1 / (8 * K_P) * sol * 1 / r * cl * sec(gamma) * csc(abs(phi)) * sin(phi + gamma);

    gphi = (tgSpeed .* sin(phi) - airspeed .* cos(phi)) .* sin(phi) - ...
           sgn(phi, SIGNUM_ZERO) * 1 / (8 * r) * sol * cl * sec(gamma) * ...
           (tgSpeed ./ K_T .* cos(phi + gamma) + airspeed ./ K_P .* sin(phi + gamma));

end

function plotgfunc(i, allphi, allg, unk0)
    % PLOTGPHI Plots the g(phi) equation from Stahlhut

    figname = ['g(phi) for element ', num2str(i)];
    figname_latex = ['$g(\phi)$ for element ', num2str(i)];
    figure('Name', figname);

    plot(rad2deg(allphi), allg);
    grid on;
    xlim(rad2deg(unk0));

    hXLabel = xlabel('Inflow angle, $\phi$ [deg]');
    hYLabel = ylabel('$g(\phi)$');
    hTitle = title(figname_latex);

    set(gca, 'FontName', 'Helvetica');
    set(gca, 'Fontsize', 14);
    set([hXLabel, hYLabel, hTitle], 'interpreter', 'latex', 'Fontsize', 14);
    set(gcf, 'PaperPositionMode', 'auto');

end
