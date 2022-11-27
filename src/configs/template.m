% TEMPLATE Template configuration file for Rotare.
%   This file gather all options, parameters and configurations needed for a complete simulation
%   with Rotare.
%   It specifies the simulation parameters, the models, the blade/rotor geometry, the operation
%   parameters and the free stream variables.
%
% Note:
%   This template does not correspond to any existing rotor. These are simply to showcase the
%   various configuration settings available.
%
% Documentation:
%   More details regarding this file and the possible configurations parameters can be found in the
%   documentation of Rotare <a href="https://gitlab.uliege.be/thlamb/rotare-doc/">online</a>.
%
% Input Validation:
%   Before being used by Rotare, this configuration file will be passed through a validation
%   function (validateconfig) that will check if all inputs are properly formatted. If that step
%   fails, an error message will be displayed with details on how to fix the configuration.
%
% Usage:
%   <strong>This is a template configuration file</strong>. It is recommended to copy it an create
%   your own configuration by modifying the copy. That way you will always be able to fallback on
%   this template if needed, or read comments with explanation in case you deleted them.
% -----
%
% Syntax:
%   run('template');
%
% Inputs:
%   /
%
% Outputs:
%   Sim     : General simulation parameters
%   Mod     : Models and solver parameters
%   Flow    : Free stream parameters
%   Design  : Operating points of the rotor to simulate
%   Airfoil : Airfoil parameters
%   Blade   : Blade and rotor geometric parameters
%
% See also: rotare, validconfig.
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
% =============================== General simulation options =======================================
% ==================================================================================================

% Autosave
Sim.Save.autosave    = false;       % Auto-save the simulation results in a mat file
Sim.Save.overwrite   = false;       % Overwrite previous result if filename is the same
Sim.Save.dir         = '../results/';  % Directory where the results are saved
Sim.Save.filename    = 'tempalteRes';  % File name of the saved result
Sim.Save.appendInfo  = true;        % Auto append config information to filename
Sim.Save.prependTime = false;       % Add the time code before the filename
Sim.Save.timeFormat = 'YYYYmmddTHHMM'; % Format for the time code

% Outputs
Sim.Out.showPlots = true;  % Show all plots (forces, angles, speed, ...)
Sim.Out.show3D    = true;  % Show the 3D view of the whole rotor
Sim.Out.hubType   = 'tangent_ogive';  % Hub (nose cone) type on the 3D view (see docs for list)
Sim.Out.console   = true;  % Print the final results in console
Sim.Out.verbosity = 'min'; % Verbosity level of the console output ('min', 'all')

% Warnings
Sim.Warn.sonicTip = true;  % Enable warnings if tip is trans/supersonic

% Miscellaneous
Sim.Misc.nonDim = 'US';   % Non-dimensionalization factor ('US', 'EU')
Sim.Misc.appli  = 'heli'; % Type of application ('helicopter', 'propeller', 'windturbine')

% ==================================================================================================
% ==================================== Models and solvers ==========================================
% ==================================================================================================

% Solvers
Mod.solvers = 'stahlhut';  % BEMT Solver ('leishman', 'indfact', 'indvel', 'stahlhut', 'all')

% Extensions/corrections
Mod.Ext.losses = 'all';    % Include losses using Prandtl formula ('none', 'hub', 'tip', 'both')

% Numerical parameters
Mod.Num.convCrit = 1e-4;  % Convergence criterion value,
Mod.Num.maxIter  = 500;   % Maximum number of iterations for convergence calculations
Mod.Num.azimStep = 6;     % Azimuthal step (for oblique flows), [deg]
Mod.Num.relax    = 0.10;  % Relaxation coefficient (facilitate convergence of iterative schemes)

% ==================================================================================================
% ======================================== Freestream ==============================================
% ==================================================================================================

Flow.fluid = 'air';  % Fluid ('air', 'seawater', 'freshwater')

% ==================================================================================================
% ===================================== Operating points ===========================================
% ==================================================================================================

% The four "Operating points" variables can be entered as vectors in order to study one given
% geometry over many operation points (and create a whole operating map for the rotor). If you are
% only interested in one specific case, you can just enter a scalar value.
%
% Note that the code will loop on every combination of these fours. So the total number of
% simulations can be very large if you want lots of operating points.

Op.speed      = 2:5:12;             % (Axial) Velocity, [m/s]
Op.collective = [2, 5, 8];          % Collective pitch, [deg]
Op.rpm        = [1000, 1300];  % Rotor angular velocity, [RPM]
Op.altitude   = 0;                  % Flight altitude (only used if Flow.fluid = 'air'), [m]

% ==================================================================================================
% ==================================== Airfoil parameters ==========================================
% ==================================================================================================

% ------- FIRST AIRFOIL -------
Airfoil.coordFile = 'airfoil_data/naca0015.dat';
Airfoil.polarType = 'file'; % Type of polar to use ('file', 'polynomial')

% If Airfoil.polarType == 'file'
Airfoil.polarFile = 'airfoil_data/NACA_0015-Re_2e5-1e7.mat';
Airfoil.extrap = true; % Extrapolates polar over whole range of angles of attack ([-180,180] deg)

% If Airfoil.polarType == 'polynomial'
Airfoil.clPoly = [0.1101, 0.4409]; % Polynomial coefficients for Cl, [1/deg]
Airfoil.cdPoly = [0.0006, -0.0042, 0.005]; % Polynomial coefficients for Cd, [1/deg]

% ------- SECOND AIRFOIL -------
Airfoil(2).coordFile = 'airfoil_data/naca0012.dat';
Airfoil(2).polarType = 'file'; % Type of polar to use ('file', 'polynomial')

% If Airfoil.polarType == 'file'
Airfoil(2).polarFile = 'airfoil_data/NACA_0012-Re_2e5-1e7.mat';
Airfoil(2).extrap = true; % Extrapolates polar over whole range of angles of attack ([-180,180] deg)

% If Airfoil.polarType == 'polynomial'
Airfoil(2).clPoly = [0.1101, 0.4409]; % Polynomial coefficients for Cl, [1/deg]
Airfoil(2).cdPoly = [0.0006, -0.0042, 0.005]; % Polynomial coefficients for Cd, [1/deg]

% ==================================================================================================
% ================================= Blade and rotor geometry =======================================
% ==================================================================================================

% The base dimensions of the blade are given as vectors with data for some representative sections
% of the blade. These vectors should have at least 2 points (the root and the tip of the blade).
% The blade elements will be interpolated using a spline rule between the available points.

Blade.nBlades    = 3;  % Number of blades on the rotor, [-]
Blade.pitchRef = 'zerolift';  % Reference for the pitch angle value ('zerolift', 'chordline')

% Base dimensions (at least root and tip)
Blade.radius   = [0.1, 0.4, 2];     % Spanwise position of the blade base stations, [m]
Blade.chord    = [0.3, 0.27, 0.10]; % Chord at the blade base stations; [m]
Blade.twist    = [40, 30, 3];       % Twist at the blade base stations, [deg]
Blade.iAirfoil = [1, 2, 2];         % Index of the airfoil to use for the base stations, [-]

% Discretization
Blade.nElem = 100;  % Number of blade elements, [-]

% Rotor base position
Blade.hubPos = [0, 0, 0]; % Rotor center position (used for coaxial rotors), [m]
Blade.spinDir = 1;        % Rotor spin direction (used for coaxial rotors; 1 = cw, -1 = ccw)
