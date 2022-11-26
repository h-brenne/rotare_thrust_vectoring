function coeff = calccoeff(self, type)
    % CALCPERF Transform one property into its associated coefficient.
    %   This method transforms the property referenced by 'type' into the associated coefficient.
    %
    % Note:
    %   The calculation of the coefficient depends on the type of application (helicopter, propeller
    %   or windturbine) and the reference system used (US or EU). These are precised respectively in
    %   'self.Rot.appli' and 'self.nonDim'. More details regarding the coefficients can be found in
    %   the documentation.
    % -----
    %
    % Syntax:
    %   OpRot.calccoeff(type) Calculate the coefficient linked to 'type'.
    %
    % Inputs:
    %   type : Input to convert. Can be 'thrust', 'torque' or 'power'.
    %
    % Outputs:
    %    coeff : the coefficient linked to 'type'.
    %
    % See also: OperRot.
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

    % Abbreviations
    dens = self.Op.Flow.rho;

    % Calculate coefficient
    switch self.Rot.appli
        case 'propeller'
            d = self.Rot.radius * 2;
            area = d^2;
            speed = self.Op.rps * d;
            nondim = getnondim(type, dens, area, speed, d);

        case 'helicopter'
            area = pi * self.Rot.radius^2;
            nondim = getnondim(type, dens, area, self.Op.omega * self.Rot.radius, self.Rot.radius);

        case 'windturbine'
            area = pi * self.Rot.radius^2;
            nondim = 0.5 * getnondim(type, dens, area, self.Op.speed, self.Rot.radius);
    end

    % EU notation has an extra 0.5 factor, except for wind turbines
    if strcmp(self.nonDim, 'EU') && ~strcmp(self.Rot.appli, 'windturbine')
        nondim = nondim * 0.5;
    end

    % Calculate the coefficient
    coeff = self.(type) / nondim;

end

function nondim = getnondim(type, dens, area, speed, len)
    % GETNONDIM Calculate the non-dimensionalization factor

    switch type
        case 'thrust'
            nondim = dens * area * speed^2;
        case 'torque'
            nondim = dens * area * speed^2 * len;
        case 'power'
            nondim = dens * area * speed^3;
    end

end
