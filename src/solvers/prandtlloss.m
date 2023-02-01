function lossFact = prandtlloss(nBl, r, r0, phi, type)
    % PRANDTLLOSS Calculate Prandtl loss factor.
    %   This function calculates the Prandtl loss factor using the generic definition from Stahlhut
    %   This formulation does not relies on the "small angles approximation" made by Leishman.
    % -----
    %
    % Syntax:
    %   lossFact = prandtlloss(nBl, r, r0, phi, type) Calculate Prandtl loss factor.
    %
    % Inputs:
    %   nBl  : Number of blades, [-]
    %   r    : Non-dimensional radial position of the elements, [-]
    %   r0   : Non-dimensional radial position of the root cutout, [-]
    %   phi  : Inflow angle of the elements, [rad]
    %   type : Type of loss to take into account ('none', 'hub', 'tip', 'all')
    %
    % Outputs:
    %   lossFact : Value for the Prandtl loss factor
    %
    % Examples:
    %   r = 0.2:0.1:1;
    %   phi = (1+0.01)*ones(size(r));
    %   F = prandtlloss(3, r, r(1)-(dy/2)/R, phi, 'all')
    %
    % See also: rotare, bemt, leishman, stahlhut.
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

    % Input check
    EXP_LOSSES = {'none', 'hub', 'tip', 'both', 'all'};

    validateattributes(nBl, {'double'}, ...
                       {'scalar', 'nonempty', 'nonnegative'}, ...
                       mfilename(), 'nBl', 1);
    validateattributes(r, ...
                       {'double'}, {'vector', 'nonempty', 'nonnegative'}, ...
                       mfilename(), 'r', 2);
    validateattributes(r0, ...
                       {'double'}, {'scalar', 'nonempty', 'nonnegative'}, ...
                       mfilename(), 'r0', 3);
    validateattributes(phi, {'double'}, ...
                       {'vector', 'nonempty', 'nonnan', 'size', size(r)}, ...
                       mfilename(), 'phi', 4);
    validatestring(type, EXP_LOSSES, mfilename(), 'Mod.losses', 5);

    % Loss factor calculation
    % -------------------------------------------

    if strcmp(type, 'none')
        lossFact = 1;
    else

        % First part of Prandtl formula for loss factor
        f_tip = (nBl / 2) * (1 - r) ./ (r .* sin(phi));
        f_root = (nBl / 2) * (r - r0) ./ (r .* sin(phi));

        % Overall loss factor
        switch type
            case 'tip'
                lossFact = lossfactor(f_tip);
            case 'hub'
                lossFact = lossfactor(f_root);
            otherwise
                lossFact = lossfactor(f_tip) .* lossfactor(f_root);
        end
    end

end

% --------------------------------------------------------------------------------------------------
function lossF = lossfactor(f)
    % LOSSFACTOR Second part of Prandtl formula for loss factor.

    lossF = (2 / pi) * acos(exp(-f));

end
