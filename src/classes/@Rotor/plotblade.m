function plotblade(self, pitch, nSec, varargin)
    % PLOTBLADE 3D plot of a single blade.
    %   This method generates a 3D plot of the blade.
    %   If provided, it can also colorize the blade elements using some input data (e.g. cT, cP,
    %   dL, etc.).
    % -----
    %
    % Syntax:
    %   Rot.plotblade() draws a 3D plot of a single blade with default colors.
    %
    %   Rot.plotblade(pitch) pitches the blade according to the `pitch` angle in radians. If not
    %   specified, no pitch will be applied.
    %
    %   Rot.plotblade(pitch, nSec) specifies the number of sections to explicitely draw. If not
    %   specified, all sections will be drawned on top of the blade outline.
    %
    %   Rot.plotblade(..., 'data', vector) draws the 3D of a single blade and colorize the sections
    %   using the values found in 'data'.
    %
    %   Rot.plotblade(..., 'newFig', true) decide if plot should be on a new figure or on current
    %   axes (false by default).
    %
    %   Rot.plotblade(..., surfProp, {Name, Value}) specifies the surface plot properties using one
    %   or more name-value pair arguments. See 'help surf' for a list of properties.
    %
    %   Rot.plotblade(..., secProp, {Name, Value}) specifies the section plot properties using one
    %   or more name-value pair arguments. See 'help plot3' for a list of properties.
    %
    % Inputs:
    %   data    : Vector to use for colorizing the blade elements (typically cT, cQ, etc).
    %             Size must be equal to Rot.Bl.nElem.
    %   nSec    : Scalar corresponding to the number of sections to explicitely draw on top of the
    %             blade surface. If set to 0, all sections will be drawn.
    %
    % Outputs:
    %    3D plot(s)
    %
    % Examples:
    %   Rot.plotblade()
    %   Rot.plotblade(deg2rad(10))
    %   Rot.plotblade(deg2rad(10), 5)
    %   Rot.plotblade('data', cT)
    %   Rot.plotblade('newFig', true)
    %   Rot.plotblade('surfProp', {'FaceAlpha', 1, 'FaceColor','blue'})
    %   Rot.plotblade('secProp', {'LineWidth', 1, 'LineStyle','--'})
    %
    % See also: rotor, rotare, template.
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

    import af_tools.formatairfoilcoord

    % Defaults and Constants
    DEF.N_SEC = 0; % All sections by default
    DEF.AF_POINTS = 31; % Plot 30 points per airfoil
    DEF.PITCH_AXIS = 0.25;  % Blades are pitched according to the quarter-chord
    DEF.CHORD_SPACING_RULE = 'halfcosine';

    if nargin < 2
        pitch = 0;
    end
    if nargin < 3
        nSec = 0;
    end

    % Determine indexes of sections to be plotted
    if nSec == 0 || nSec >= length(self.Bl.r)
        iSec = 1:1:length(self.Bl.r);
    else
        iSec = floor(linspace(1, length(self.Bl.r), nSec));
    end

    % Input validation
    valData = @(x) validateattributes(x, {'numeric'}, ...
                                      {'row', 'nonempty', 'numel', length(self.Bl.chord)});
    valLogi = @(x) validateattributes(x, {'logical'}, {'scalar'});
    % valPlotOpts = @(x) validateattributes(x, {'logical'}, {'scalar'}); % FIXME

    p = inputParser;
    p.FunctionName = 'plot';
    addOptional(p, 'data', zeros(size(self.Bl.chord)), valData);
    addOptional(p, 'newFig', false, valLogi);
    addOptional(p, 'surfProp', {});
    addOptional(p, 'secProp', {});
    parse(p, varargin{:});
    data = p.Results.data;
    newFig = p.Results.newFig;
    surfProp = p.Results.surfProp;
    secProp = p.Results.secProp;

    % -------------------------------------------
    % Normalize airfoil coordinates so they all have the same X components and number of points
    coords = normalizeafcoord(self, DEF);

    % Create matrices to scale and apply color appropriately
    chordMat = repmat(self.Bl.chord, length(coords(:, 1)), 1);
    dataMat = repmat(data, length(coords(:, 1)), 1);

    % Scale elements and twist them properly to create the correct blade
    Blade = gettrueposition(self.Bl, coords, chordMat, pitch, DEF);

    % Plot blade and rotor
    if newFig
        figname = 'Single Blade';
        figure('PaperUnits', 'inches', 'PaperPosition', [0 0 1280 1024] / 250, 'Name', figname);
        hAx = axes('NextPlot', 'add');
    else
        hAx = axes;
    end
    bladeplot(Blade, dataMat, hAx, iSec, surfProp, secProp);

    if newFig
        setgca();
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

function Blade = gettrueposition(Elem, coords, chordMat, pitch, DEF)
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
        rotY = roty(rad2deg(Elem.twist(i) + pitch));
        dummy = rotY * [geomX(:, i), geomY(:, i), geomZ(:, i)]';
        Blade.x(:, i) = dummy(1, :);
        Blade.y(:, i) = dummy(2, :);
        Blade.z(:, i) = dummy(3, :);
    end

end

function bladeplot(Blade, dataMat, handleAxis, iSec, surfProp, secProp)
    % PLOTBLADE  Plot a single blade (color surface + outline)

    DEF_SURFACE_PROP = {'EdgeColor', 'none', 'FaceAlpha', 0.3};
    DEF_SECTION_PROP = {'Color', 'k'};
    if isempty(surfProp)
        surfProp = DEF_SURFACE_PROP;
    end
    if isempty(secProp)
        secProp = DEF_SECTION_PROP;
    end

    surf(Blade.x, Blade.y, Blade.z, dataMat, 'Parent', handleAxis, surfProp{:});
    hold on;
    plot3(Blade.x(:, iSec), Blade.y(:, iSec), ...
          Blade.z(:, iSec), 'Parent', handleAxis, secProp{:});
    % Set the axis labels using LaTeX interpreter
    %xlabel(handleAxis, '$m$', 'Interpreter', 'latex');
    %ylabel(handleAxis, '$m$', 'Interpreter', 'latex');
    %zlabel(handleAxis, '$m$', 'Interpreter', 'latex');

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
