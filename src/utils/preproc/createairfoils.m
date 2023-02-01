function Af = createairfoils(UserAirfoil)
    % CREATEAIRFOILS Create Airfoils objects from user input.
    %   This function uses the user input to create as many Airfoil objects as necessary. It then
    %   loads the Polar object associated with each airfoil (or create it on-the-spot based on raw
    %   XFOIL/XFLR5 output). After that, the Polars are extended to cover the whole range of angles
    %   of attacks ([-180, 180] deg) using a flat plate assumption for the large angles. Finally,
    %   all important metrics are calculated for each Polar (stall, zero lift, linear range).
    % -----
    %
    % Syntax:
    %   Af = createairfoils(UserAirfoil)
    %
    % Inputs:
    %   UserAirfoil : Structure defining the various properties for each airfoil.
    %   See `configs/template.m` for an example. See also the user manual for a complete detail of
    %   every parameter.
    %
    % Outputs:
    %   Af : Airfoil object, with all fields completed from the user input. If the input structure
    %   is of dimension N, `Af` will also be of dimension N.
    %
    % Examples:
    %   Af = createairfoils(Airfoil)
    %
    % See also: rotare, template.
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

    import af_tools.*

    for i = length(UserAirfoil):-1:1  % Reverse loop to ensure pre-allocation

        % Construct object
        Af(i) = Airfoil(UserAirfoil(i).coordFile);

        % Fill in the Polar object
        switch UserAirfoil(i).polarType
            case 'file'
                Af(i) = Af(i).loadpolar(UserAirfoil(i).polarFile);
            case 'polynomial'
                Af(i) = Af(i).Polar.polypolar(UserAirfoil(i).clPoly, UserAirfoil(i).cdPoly);
        end

        % Extend the polar and get the important properties
        Af(i).Polar.extendpolar();
        Af(i).Polar.analyze();

    end

end
