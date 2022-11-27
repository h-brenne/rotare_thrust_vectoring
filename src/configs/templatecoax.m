% TEMPLATECOAX Template configuration file for Coaxial rotors simulations with Rotare.
%  This file extends the regular template configuration by adding a second rotor geometry.
% -----
%
% See also: template, rotare, validconfig.
%
% <a href="https://gitlab.uliege.be/thlamb/rotare-doc">Complete documentation (online)</a>

% --------------------------------------------------------------------------------------------------
% (c) Copyright 2022 University of Liege
% Author: Thomas Lambert <t.lambert@uliege.be>
% ULiege - Aeroelasticity and Experimental Aerodynamics
% MIT License
% Repo: https://gitlab.uliege.be/thlamb/rotare
% Docs: https://gitlab.uliege.be/thlamb/rotare-doc
% Issues: https://gitlab.uliege.be/thlamb/rotare/-/issues
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% ==================================================================================================
% ================================== Baseline configuration ========================================
% ==================================================================================================
template; % Just load exisiting template

% ==================================================================================================
% ================================= Blade and rotor geometry =======================================
% ==================================================================================================
% Adds a second element to the blade structure to represent the second rotor

Blade(2) = Blade(1); % Make second rotor identical to first one

if strcmp(Sim.Misc.appli, 'heli')
    rotorShift = [0, 0, -1];
else
    rotorShift = [-1, 0, 0];
end
Blade(2).hubPos = Blade(1).hubPos - rotorShift; % Shift second rotor w.r.t the application type

% ==================================================================================================
% ===================================== Operating points ===========================================
% ==================================================================================================

% Operating points must be set for the two rotors
% We simply extend the collective and rpm fields by adding values for the new rotor
Op.collective = [Op.collective; 1, 4, 7];
Op.rpm = [Op.rpm; 900, 1200];
