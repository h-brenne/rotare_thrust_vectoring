% KNIGHT1937 Configuration file for Knight & Hefner rotor (NACA TN-626)
%  This file is used to simulate the experiment described in NACA TN-626 with Rotare.
% -----
%
% See also: template, rotare, validconfig.
%
% <a href="https://gitlab.uliege.be/rotare/documentation">Complete documentation (online)</a>

% --------------------------------------------------------------------------------------------------
% Ref: Knight and Hefner, "Static Thrust Analysis of the Lifting Airscrew". 1937. NASA. (TN-626)
% --------------------------------------------------------------------------------------------------
% (c) Copyright 2022-2023 University of Liege
% Author: Thomas Lambert <t.lambert@uliege.be>
% ULiege - Aeroelasticity and Experimental Aerodynamics
% MIT License
% Repo: https://gitlab.uliege.be/rotare/rotare
% Docs: https://gitlab.uliege.be/rotare/documentation
% Issues: https://gitlab.uliege.be/rotare/rotare/-/issues
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Autosave
Sim.Save.autosave    = true;       % Auto-save the simulation results in a mat file
Sim.Save.overwrite   = true;       % Overwrite previous result if filename is the same
Sim.Save.dir         = '../results/';  % Directory where the results are saved
Sim.Save.filename    = 'knight2';  % File name of the saved result
Sim.Save.appendInfo  = true;        % Auto append config information to filename
Sim.Save.prependTime = false;       % Add the time code before the filename
Sim.Save.timeFormat = 'YYYYmmddTHHMM'; % Format for the time code

% Outputs
Sim.Out.showPlots = false;  % Show all plots (forces, angles, speed, ...)
Sim.Out.show3D    = true;  % Show the 3D view of the whole rotor
Sim.Out.hubType   = 'none';  % Hub (nose cone) type on the 3D view (see docs for list)
Sim.Out.console   = true;  % Print the final results in console
Sim.Out.verbosity = 'min'; % Verbosity level of the console output ('min', 'all')

% Warnings
Sim.Warn.sonicTip = true;  % Enable warnings if tip is trans/supersonic

% Miscellaneous
Sim.Misc.nonDim = 'EU';   % Non-dimensionalization factor ('US', 'EU')
Sim.Misc.appli  = 'heli'; % Type of application ('helicopter', 'propeller', 'windturbine')

% ==================================================================================================
% ==================================== Models and solvers ==========================================
% ==================================================================================================

% Solvers
Mod.solvers = {'all'};   % BEMT Solver ('leishman', 'indfact', 'indvel', 'stahlhut', 'all')

% Extensions/corrections
Mod.Ext.losses = 'all';  % Include losses using Prandtl formula ('none', 'hub', 'tip', 'both')

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

Op.speed      = 0;              % (Axial) Velocity, [m/s]
Op.collective = 1:12;           % Collective pitch, [deg]
Op.rpm        = 960;            % Rotor angular velocity, [RPM]
Op.altitude   = 0;              % Flight altitude (only used if Flow.fluid = 'air'), [m]

% ==================================================================================================
% ==================================== Airfoil parameters ==========================================
% ==================================================================================================

% ------- FIRST AIRFOIL -------
Airfoil.polarType = 'file'; % Type of polar to use ('file', 'polynomial')
Airfoil.coordFile = 'airfoil_data/naca0015.dat';

% If Airfoil.polarType == 'file'
Airfoil.polarFile = 'airfoil_data/NACA_0015-Re_2e5-1e7.mat';
Airfoil.extrapMethod = 'viterna'; % Polar extrapol. ('none', 'spline', 'viterna')

% ==================================================================================================
% ================================= Blade and rotor geometry =======================================
% ==================================================================================================

% The base dimensions of the blade are given as vectors with data for some representative sections
% of the blade. These vectors should have at least 2 points (the root and the tip of the blade).
% The blade elements will be interpolated using a spline rule between the available points.

Blade.nBlades    = 2;  % Number of blades on the rotor, [-]
Blade.pitchRef = 'chordline';  % Reference for the pitch angle value ('zerolift', 'chordline')

% Base dimensions (at least root and tip)
Blade.radius   = [0.127, 0.7620];  % Spanwise position of the blade base stations, [m]
Blade.chord    = [0.0508, 0.0508]; % Chord at the blade base stations; [m]
Blade.twist    = [0, 0];           % Twist at the blade base stations, [deg]
Blade.iAirfoil = [1, 1];           % Index of the airfoil to use for the base stations, [-]

% Discretization
Blade.nElem = 100;  % Number of blade elements, [-]

% Rotor base position
Blade.hubPos = [0, 0, 0]; % Rotor center position (used for coaxial rotors), [m]
