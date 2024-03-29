function [cl, cd] = getclcd(self, aoaVect, reyVect, i)
    % GETCLCD Returns the cl and cd of one or all elements using the Airfoil polars.
    %   This function returns the lift and drag coefficients based on the Airfoil object,
    %   the index of the airfoil at a given element, the angle of attack of the element and its
    %   Reynolds number.
    % -----
    %
    % Syntax:
    %   [cl, cd] = getclcd(self) Returns the cl and cd of all elements using the aoa and reynolds
    %   values in the properties of the element.
    %
    %   [cl, cd] = getclcd(self, aoaVect) Returns the cl and cd of all elements using the angles of
    %   attack supplied and the reynolds values in the properties of the element.
    %
    %   [cl, cd] = getclcd(self, aoaVect, reyVect) Returns the cl and cd of all elements using the
    %   angles of attack and the reynolds supplied as inputs.
    %
    %   [cl, cd] = getclcd(self, aoaVect, reyVect, i) Returns the cl and cd of the element 'i'
    %   for the angle of attack aoaVect and the reynolds number reyVect
    %
    % Inputs:
    %   aoaVect : (optional) Angles of attack, [rad]
    %   reyVect : (optional) Reynolds number, [-]
    %
    % Outputs:
    %   cl : Element lift coefficient, [-]
    %   cd : Element drag coefficient, [-]
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

    % Abbreviations
    Af = self.Rot.Af;
    iAf = self.Rot.Bl.iAf;

    % Input parsing
    if nargin < 2 || isempty(aoaVect)
        aoaVect = self.alpha;
    end
    if nargin < 3 || isempty(reyVect)
        reyVect = self.reynolds;
    end

    % Get the proper cl and cd for each element
    if nargin < 4 || isempty(i)
        cl = zeros(size(aoaVect));
        cd = zeros(size(aoaVect));

        for i = 1:length(Af)
            idx = (iAf == i);
            if any(idx)
                [cl(idx), cd(idx)] = Af(i).Polar.getcoeffs(aoaVect(idx), reyVect(idx));
            end
        end

    else
        [cl, cd] = Af(iAf(i)).Polar.getcoeffs(aoaVect, reyVect);
    end

    if any(isnan(cl)) || any(isnan(cd))
        error('MATLAB:getclcd:NaNValues', ...
              ['No valid cl or cd found for at least one angle ' ...
               'of attack. Please review the Airfoil.extrapMethod parameter to allow for ' ...
               'extrapolation or adapt the operating conditions of the rotor to ensure '...
               'the angles of attack remain in the range allowed by the polars provided.']);
    end

end
