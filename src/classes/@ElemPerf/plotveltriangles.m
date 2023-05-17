function plotveltriangles(self, nTriangles, varargin)
    % PLOTVELTRIANGLES Plot the velocity triangles along the span.
    %   This method plots the velocity triangles along the span of the blade.
    % -----
    %
    % Syntax:
    %   ElPerf.plotveltriangles() Plot the velocity triangles for 5 linearily spaced sections along
    %   the blade.
    %
    %   ElPerf.plotveltriangles(nTriangles) Plot the velocity triangles for `nTriangles` linearily
    %   spaced sections along the blade.
    %
    % Inputs:
    %   nTriangles: Number of section to plot the velocity triangles for
    %
    % Outputs:
    %   Plots [FIXME]
    %
    %
    % See also: ElemPerf.
    %
    % <a href="https:/gitlab.uliege.be/rotare/documentation">Complete documentation (online)</a>

    % ----------------------------------------------------------------------------------------------
    % LIST OF TODOS
    %   - Should be able to plot individual sections in 2D as well (one fig per section)
    %
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
    TRI_POS_Z = 1; % Number of chords of space to display the triangle position
    VECT_SCALE_FACTOR = 2; % Number of chords of space to display the triangle position
    DEF.FIG_TYPE = '3D'; % Only 3D plot by default
    DEF.NEW_FIG = false; % New figure is false by default
    DEF.ALLOWED_FIG_TYPES = {'all', '3D', 'sections'};

    % Input check and validation
    if nargin < 2
        nTriangles = 5;
    end

    valLogi = @(x) validateattributes(x, {'logical'}, {'scalar'});
    p = inputParser;
    p.FunctionName = 'plot';
    addOptional(p, 'figType', DEF.FIG_TYPE, @(x) any(validatestring(x, DEF.ALLOWED_FIG_TYPES)));
    addOptional(p, 'newFig', DEF.NEW_FIG, valLogi);
    parse(p, varargin{:});
    figType = p.Results.figType;
    newFig = p.Results.newFig;

    % Velocity triangles
    % FIXME: Needs adaptation for coaxial
    vAx_up = ones(size(self.tgSpeed)) * self.Op.speed;
    vTg_up = self.tgSpeed;

    vAx_rot = self.Op.speed + self.indVelAx;
    vTg_rot = self.tgSpeed - self.indVelTg;

    vAx_down = self.Op.speed + 2 * self.indVelAx;
    vTg_down = self.tgSpeed - 2 * self.indVelTg;

    % Determine sections to be plotted
    if nTriangles == 0 || nTriangles > length(self.Rot.Bl.r)
        iSec = 1:length(self.Rot.Bl.r);
    else
        iSec = floor(linspace(1, length(self.Rot.Bl.r), nTriangles));
    end

    % Vectors will need to be scaled down otherwise it is 100x too large.
    % Good scaling: tip speed should be similar to n Chords
    scale = VECT_SCALE_FACTOR * self.Rot.Bl.chord(1) / (self.Op.omega * self.Rot.radius);
    zSpace = TRI_POS_Z * self.Rot.Bl.chord(1) / scale;

    % Actual plotting of the blade
    if strcmpi(figType, 'all') || strcmpi(figType, '3D')
        if newFig
            figure('Name', 'Velocity triangles along the blade');
        end

        self.Rot.plotblade(nTriangles);
        hold on;

        for i = iSec
            plottri(0, self.Rot.Bl.y(i), zSpace, vAx_up(i), vTg_up(i), scale, 3); % Upstream
            plottri(0, self.Rot.Bl.y(i), 0, vAx_rot(i), vTg_rot(i), scale, 3); % At the disk
            plottri(0, self.Rot.Bl.y(i), -zSpace, vAx_down(i), vTg_down(i), scale, 3); % Downstream

        end
        axis equal;

    end

end

function plottri(x, y, z, vAx, vTg, size, dim)
    % PLOTTRI Plot a triangle with the resulting pointing in (x,y,z)

    COLOR_AX = [168, 88, 158] / 255; % Purple
    COLOR_TG = [240, 127, 60] / 255;   % Orange
    COLOR_RES = [0, 112, 127] / 255;   % Blue-green

    if nargin < 6
        size = 0;
    end
    if nargin < 7
        dim = 2;
    end

    coordSize = 1;
    if size ~= 0
        coordSize = size;
    end

    if dim == 2
        % Plot the vectors in 2D
        quiver(x * coordSize, (z + vAx) * coordSize, 0, -vAx, size);
        quiver((x - vTg) * coordSize, (z + vAx) * coordSize, vTg, 0, size);
        quiver((x - vTg) * coordSize, (z + vAx) * coordSize, vTg, -vAx, size);
    else
        % Plot the vectors so resulting speed ends up in (x,y,z)
        quiver3(x * coordSize, y, (z + vAx) * coordSize, ...
                0, 0, -vAx, ...
                size, 'color', COLOR_AX, 'linewidth', 1.5);
        quiver3((x - vTg) * coordSize, y, (z + vAx) * coordSize, ...
                vTg, 0, 0, ...
                size, 'color', COLOR_TG, 'linewidth', 1.5);
        quiver3((x - vTg) * coordSize, y, (z + vAx) * coordSize, ...
                vTg, 0, -vAx, ...
                size, 'color', COLOR_RES, 'linewidth', 2);
    end

end
