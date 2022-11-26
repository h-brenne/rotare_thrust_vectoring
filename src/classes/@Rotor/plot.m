function plot(self, varargin)
    % PLOT 3D plot of the full rotor or of a single blade.
    %   This method generates 3D plots of the rotor. It can either represent the complete rotor
    %   (and a generic hub), or only a single isolated blade.
    %   If provided, it can also colorize the blade elements using some input data (e.g. cT, cP,
    %   dL, etc.).
    % -----
    %
    % Syntax:
    %   Rot.plot() draws a 3D plot of a single blade and an other one of the complete rotor,
    %   without colors.
    %
    %   Rot.plot(type) draws the 3D plots specified by 'type', without colors.
    %
    %   Rot.plot(type, hubType) draws the 3D plots specified by 'type', without colors. Uses
    %   the geometry specified in 'hubType' for the hub. Note that this is purely visual, the
    %   hubType has absolutely no impact on the computations and results of Rotare.
    %
    %   Rot.plot(type, hubType, data) draws the 3D plots specified by 'type' and using the
    %   'hubType' geometry for the hub. The 'data' vector is then used to colorize the elements of
    %   the blade on the various plots.
    %
    % Inputs:
    %   type    : Type of plot desired. Can be one of the following:
    %               - 'blade': a single blade
    %               - 'rotor': the complete rotor
    %               - 'all' or 'both': a single blade and the complete rotor
    %   hubType : Type of hub to plot on the rotor 3D plot. Can be one of the following: 'none',
    %             'cylinder', 'conic', 'blunted_conic', 'bi-conic', 'tangent_ogive',
    %             'blunted_tangent_ogive', 'secant_ogive_regular', 'secant_ogive_bulge',
    %             'elliptical', 'parabolic', 'power_series', 'lv-haack', 'vonkarman'.
    %   data    : Vector to use for colorizing the blade elements (typically cT, cQ, etc).
    %             Size must be equal to Rot.Bl.nElem.
    %
    % Outputs:
    %    3D plot(s)
    %
    % Examples:
    %   Rot.plot()
    %   Rot.plot('all')
    %   Rot.plot('all', 'bi-conic')
    %   Rot.plot('all', 'bi-conic', thrustCoeff)
    %
    % See also: rotor, rotare, template.
    %
    % <a href="https://gitlab.uliege.be/thlamb/rotare-doc">Complete documentation (online)</a>

    % ----------------------------------------------------------------------------------------------
    % (c) Copyright 2022 University of Liege
    % Author: Thomas Lambert <t.lambert@uliege.be>
    % ULiege - Aeroelasticity and Experimental Aerodynamics
    % MIT License
    % Repo: https://gitlab.uliege.be/thlamb/rotare
    % Docs: https://gitlab.uliege.be/thlamb/rotare-doc
    % Issues: https://gitlab.uliege.be/thlamb/rotare/-/issues
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    narginchk(1, 4);

    import af_tools.formatairfoilcoord

    % Defaults and Constants
    DEF.SPACING = 1;    % Plot lines every N elements of the blade
    DEF.AF_POINTS = 31; % Plot 30 points per airfoil
    DEF.PITCH_AXIS = 0.25;  % Blades are pitched according to the quarter-chord
    DEF.CHORD_SPACING_RULE = 'halfcosine';

    DEF.ALLOWED_TYPES = {'blade', 'rotor', 'all'};
    DEF.ALLOWED_HUBS = {'none', 'cylinder', 'conic', 'blunted_conic', 'bi-conic', ...
                        'tangent_ogive', 'blunted_tangent_ogive', 'secant_ogive_regular', ...
                        'secant_ogive_bulge', 'elliptical', 'parabolic', 'power_series', ...
                        'lv-haack', 'vonkarman'};
    DEF.CONE_RAD = 1.2; % Cone radius multiplier ( val * Rot.cutout)
    DEF.CONE_LEN = 2.45; % Cone length multiplier ( val * cone_radius)
    CONE_COLOR = [0 0.4470 0.7410];

    % Input validation
    valData = @(x) validateattributes(x, {'numeric'}, ...
                                      {'row', 'nonempty', 'numel', length(self.Bl.chord)});
    p = inputParser;
    p.FunctionName = 'plot';
    addOptional(p, 'type', 'all', @(x) any(validatestring(x, DEF.ALLOWED_TYPES)));
    addOptional(p, 'hubType', 'none', @(x) any(validatestring(x, DEF.ALLOWED_HUBS)));
    addOptional(p, 'data', zeros(size(self.Bl.chord)), valData);
    parse(p, varargin{:});
    type = p.Results.type;
    hubType = p.Results.hubType;
    data = p.Results.data;

    % -------------------------------------------
    % Normalize airfoil coordinates so they all have the same X components and number of points
    coords = normalizeafcoord(self, DEF);

    % Create matrices to scale and apply color appropriately
    chordMat = repmat(self.Bl.chord, length(coords(:, 1)), 1);
    dataMat = repmat(data, length(coords(:, 1)), 1);

    % Scale elements and twist them properly to create the correct blade
    Blade = gettrueposition(self.Bl, coords, chordMat, DEF);

    % Plot blade and rotor
    if any(strcmp(type, {'all', 'blade'}))

        figname = 'Single Blade';
        figure('PaperUnits', 'inches', 'PaperPosition', [0 0 1280 1024] / 250, 'Name', figname);
        hAx = axes('NextPlot', 'add');
        plotblade(Blade, dataMat, hAx, DEF);
        setgca();
    end

    if any(strcmp(type, {'all', 'rotor'}))

        % Generate rest of the rotor from first blade
        Blades = makerotorblades(self, Blade);

        figname = 'Full Rotor';
        figure('PaperUnits', 'inches', 'PaperPosition', [0 0 1280 1024] / 250, 'Name', figname);
        hAx = axes('NextPlot', 'add');
        for iBl = 1:self.nBlades
            plotblade(Blades(iBl), dataMat, hAx, DEF);
        end

        % Plot rotor cone
        if ~strcmp(hubType, 'none')
            % Cone radius and length
            coneRad = DEF.CONE_RAD * self.cutout;
            coneLen = DEF.CONE_LEN * coneRad;

            % Create nose cone and position it properly
            Nc = NoseCone(hubType, coneRad, coneLen);
            Nc.pos = self.position; % Cone at the center of the rotor
            % Offset the cone so the blade falls in the middle and not at the tip
            Nc.offset = min(min(Blade.z(:, 1:DEF.SPACING:end)));

            % Place cone vertically for propellers and windturbines
            if ~(strcmp(self.appli, 'helicopter'))
                Nc.rotY = -90;
            end

            % Plot the nose cone
            Nc.plot(CONE_COLOR);
        end

        setgca();

        % Workaround for axis equal and square at the same time
        axLim = [xlim; ylim; zlim];
        xlim([min(axLim(:, 1)), max(axLim(:, 2))]);
        ylim([min(axLim(:, 1)), max(axLim(:, 2))]);
        zlim([min(axLim(:, 1)), max(axLim(:, 2))]);

    end

end

% --------------------------------------------------------------------------------------------------
function coords = normalizeafcoord(self, DEF)
    % NORMALIZEAFCOORD  Normalizes airfoil coordinates
    %   This ensures all airfoils will share the same X coordinates and number of points
    %   and simplifies further drawings

    import af_tools.utils.spacedvector

    % Get a vector for chordwise positions
    xpts = spacedvector(DEF.CHORD_SPACING_RULE, DEF.AF_POINTS);
    xpts = xpts(:); % Ensure it is a column vector

    % Interpolate Y coordinate for all airfoils on the new points
    ypts = zeros(DEF.AF_POINTS * 2 - 1, length(self.Af));
    for i = 1:length(self.Af)
        yptsUp = interp1(self.Af(i).upper(:, 1), self.Af(i).upper(:, 2), flipud(xpts));
        yptsLow = interp1(self.Af(i).lower(:, 1), self.Af(i).lower(:, 2), xpts);
        ypts(:, i) = [yptsUp; yptsLow(2:end)];
    end

    % Combine the new coordinates in a single array
    xpts = [flipud(xpts); xpts(2:end)];
    coords = [xpts, ypts];

end

function Blade = gettrueposition(Elem, coords, chordMat, DEF)
    % GETTRUEPOSITION  Returns the true position of the blade elements after scaling and twisting

    % Scale the blade to actual chord and span
    geomX = repmat(coords(:, 1) - DEF.PITCH_AXIS, 1, length(Elem.chord)) .* chordMat;
    geomY = repmat(Elem.y, length(coords(:, 1)), 1);
    geomZ = zeros(size(geomX));
    for i = 1:length(Elem.chord)
        geomZ(:, i) = coords(:, 1 + Elem.iAf(i)) .* chordMat(:, i);
    end

    % Pitch the airfoil according to the correct local twist angle
    for i = 1:length(Elem.chord)
        rotY = roty(rad2deg(Elem.twist(i)));
        dummy = rotY * [geomX(:, i), geomY(:, i), geomZ(:, i)]';
        Blade.x(:, i) = dummy(1, :);
        Blade.y(:, i) = dummy(2, :);
        Blade.z(:, i) = dummy(3, :);
    end

end

function Blades = makerotorblades(self, Blade)
    % MAKEROTORBLADES Create the other blades to complete the whole rotor
    %   1. Create rotor by rotating the first blade around the vertical axis
    %   2. Rotate the rotor around horizontal axis w.r.t. current application
    %   3. Reposition the rotor center properly

    % First blade already known
    Blades = Blade;

    % Position other blades by rotating the components of the first one around vertical axis
    for iBl = 2:self.nBlades
        posAngle = 360 / self.nBlades * (iBl - 1);

        for i = 1:length(Blade.x(:, 1))
            dummy = rotz(posAngle) * [Blade.x(i, :); Blade.y(i, :); Blade.z(i, :)];
            Blades(iBl).x(i, :) = dummy(1, :);
            Blades(iBl).y (i, :) = dummy(2, :);
            Blades(iBl).z(i, :) = dummy(3, :);
        end

    end

    % Place rotor vertically for propellers and windturbines
    if ~(strcmp(self.appli, 'helicopter'))
        for iBl = 1:self.nBlades
            for i = 1:length(Blade.x(:, 1))
                dummy = roty(90) * [Blades(iBl).x(i, :); Blades(iBl).y(i, :); Blades(iBl).z(i, :)];
                Blades(iBl).x(i, :) = dummy(1, :);
                Blades(iBl).y (i, :) = dummy(2, :);
                Blades(iBl).z(i, :) = dummy(3, :);
            end
        end
    end

    % Position the rotor properly
    for iBl = 1:self.nBlades
        Blades(iBl).x = Blades(iBl).x + self.position(1);
        Blades(iBl).y = Blades(iBl).y + self.position(2);
        Blades(iBl).z = Blades(iBl).z + self.position(3);
    end

end

function plotblade(Blade, dataMat, handleAxis, DEF)
    % PLOTBLADE  Plot a single blade (color surface + outline)

    surf(Blade.x, Blade.y, Blade.z, dataMat, 'EdgeColor', 'none', 'Parent', handleAxis);
    plot3(Blade.x(:, 1:DEF.SPACING:end), Blade.y(:, 1:DEF.SPACING:end), ...
          Blade.z(:, 1:DEF.SPACING:end), ...
          '-k', 'Parent', handleAxis);

end

function setgca()
    % SETGCA Sets axes options for all plots

    view(3);
    grid on;
    axis equal;
    % hCol=colorbar;
    % hCol.Label.String = 'Sectional thrust, dT [N]';
    set(gca, 'FontName', 'Helvetica');
    set(gca, 'Fontsize', 14);
    set(gca, ...
        'Box', 'off', ...
        'TickDir', 'out', ...
        'TickLength', [.02 .02], ...
        'XMinorTick', 'off', ...
        'YMinorTick', 'off', ...
        'YGrid', 'on', ...
        'XGrid', 'on', ...
        'XColor', 'k', ...
        'YColor', 'k', ...
        'GridLineStyle', ':', ...
        'GridColor', 'k', ...
        'GridAlpha', 0.25, ...
        'LineWidth', 1);
    set(gcf, 'PaperPositionMode', 'auto');

end
