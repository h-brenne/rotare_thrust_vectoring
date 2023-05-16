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
    % (c) Copyright 2022-2023 University of Liege
    % Author: Thomas Lambert <t.lambert@uliege.be>
    % ULiege - Aeroelasticity and Experimental Aerodynamics
    % MIT License
    % Repo: https://gitlab.uliege.be/rotare/rotare
    % Docs: https://gitlab.uliege.be/rotare/documentation
    % Issues: https://gitlab.uliege.be/rotare/rotare/-/issues
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Input check and validation
    if nargin < 2
        nTriangles = 5;
    end

    newFig = false;

    if newFig
        figure('Name', 'Velocity triangles');
    end

    totVelAx = self.indVelAx;
    totVelTg = self.indVelTg + 100;
    figure;

    %     plot3(self.Rot.Af.coord(:,1), zeros(size(self.Rot.Af.coord,1)), self.Rot.Af.coord(:,2))
    plot(self.Rot.Af.coord(:, 1), self.Rot.Af.coord(:, 2));
    hold on;
    plottri(0, 0, 0, totVelAx(end / 2), totVelTg(end / 2), 0.005);
    axis equal;
    grid on;

    if nTriangles == 0 || nTriangles > length(self.Rot.Bl.r)

        % plot all vel tri
    else
        % pos = linspace(self.Rot.Bl.r(1), self.Rot.Bl.r(end), nTriangles)
        % pos = roundtoneares(pos, self.Rot.Bl.r)
        % plot triangles at pos
    end

end

% Round to nearest
%
%     % This solutions currently does it with loops just to get a picture of the problem.
%     A = [2000 1999 1998 1996 1993 1990];
%     B = [2000 1995 1990 1985 1980];
%     for idx1=1:length(A);
%       for idx2=1:length(B);
%           C(idx2,idx1)=A(idx1)-B(idx2);
%       end;
%     end
%     % Now find the index of the min values
%     [v,i]=min(abs(C));
%     % 'i' now contants the list of locations in B that corespond to the nearest
%     % A value
%     B(i)

function plottri(x, y, z, vAx, vTg, size, dim)
    % PLOTTRI Plot a triangle with the resulting pointing in (x,y,z)

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

    % [FIXME] Dynamic function name
    if dim == 2
        disp('coucou');
        % Plot the vectors so resulting speed ends up in (x,y,z)
        quiver(x * coordSize, (z + vAx) * coordSize, 0, -vAx, size);
        quiver((x - vTg) * coordSize, (z + vAx) * coordSize, vTg, 0, size);
        quiver((x - vTg) * coordSize, (z + vAx) * coordSize, vTg, -vAx, size);
    else
        % Plot the vectors so resulting speed ends up in (x,y,z)
        quiver3(x * coordSize, y, (z + vAx) * coordSize, 0, 0, -vAx, size);
        quiver3((x - vTg) * coordSize, y, (z + vAx) * coordSize, vTg, 0, 0, size);
        quiver3((x - vTg) * coordSize, y, (z + vAx) * coordSize, vTg, 0, -vAx, size);
    end

    % Plot the vectors so resulting speed ends up in (x,y,z)
    quiver3(x * coordSize, y, (z + vAx) * coordSize, 0, 0, -vAx, size);
    quiver3((x - vTg) * coordSize, y, (z + vAx) * coordSize, vTg, 0, 0, size);
    quiver3((x - vTg) * coordSize, y, (z + vAx) * coordSize, vTg, 0, -vAx, size);
end
