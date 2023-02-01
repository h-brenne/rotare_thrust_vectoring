function plot(self, color)
    % PLOT Plot the nose cone.
    % -----
    %
    % Syntax:
    %   NoseCone.plot() draws a 3D plot of the nose cone.
    %
    %   NoseCone.plot(color) draws a 3D plot of the nose cone, using the color specified.
    %
    % Inputs:
    %   color : Color to use for the nose cone faces
    %
    % Outputs:
    %    3D plot of the cone
    %
    % Examples:
    %   NoseCone.plot()
    %   NoseCone.plot([0 0.4 0.7])
    %
    % See also: NoseCone.
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

    % Defaults and constants
    CONE_COLOR = [0 0.4470 0.7410];

    if nargin < 2
        color = CONE_COLOR;
    end

    % Abbreviations
    X = self.coord(:, :, 1);
    Y = self.coord(:, :, 2);
    Z = self.coord(:, :, 3);

    % Plot the cone and fill the top and bottom holes
    surf(X, Y, Z, 'FaceColor', color, 'LineStyle', ':');
    fill3(X(1, :), Y(1, :), Z(1, :), color, 'LineStyle', '-');
    fill3(X(end, :), Y(end, :), Z(end, :), color, 'LineStyle', '-');

end
