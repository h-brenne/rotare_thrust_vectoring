function [Sim, Mod, Flow, Op, Airfoil, Blade] = validateconfig(configFile)
    % VALIDATECONFIG Check configuration file validity and load sanitized inputs.
    %   This function ensures the validity of the input configuration file. If any check fails, it
    %   will return an error detailing how to fix it.
    %   This function also sanitizes string inputs to ensure proper execution of the code.
    %
    % Note:
    %   The configuration structures will only be passed to the solver if all checks in this
    %   function succeed. To ensure the correct execution of Rotare, please DO NOT TRY TO BYPASS
    %   these checks.
    %   If you think there is an issue with this validator or constraints are too strict in some
    %   places, please report it on the issue tracker (link in the file header).
    % -----
    %
    % Syntax:
    %   [Sim, Mod, Flow, Op, Airfoil, Blade] = VALIDATECONFIG(configFile) validates all the various
    %   inputs specified in configFile, sanitizes strings if needed and output the validated data
    %   structures.
    %
    % Inputs:
    %   configFile : Configuration file to be checked and loaded
    %
    % Outputs:
    %    Sim     : General Simulation parameters
    %    Mod     : Models and solver parameters
    %    Flow    : Free stream parameters
    %    Op      : Operating points of the rotor
    %    Airfoil : Airfoil parameters
    %    Blade   : Blade and rotor geometric parameters
    %         or
    %    Error message with detail about the config issue.
    %
    % Examples:
    %   [Sim, Mod, Flow, Op, Airfoil, Blade] = VALIDATECONFIG('configs/myconfig.m')
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

    % Load the configuration file and output warning if it is the template.

    configFile = ensurefileext(configFile, '.m'); % Ensure proper extension

    if isfile(configFile)
        run(configFile);
        if strcmpi(configFile, 'configs/template.m')
            warning('off', 'backtrace');
            warning('ROTARE:validateconfig:useTemplate', ...
                    ['You are currently running the template configuration.\n' ...
                     'It is heavily encouraged to create a separate config for your '...
                     'system (by copying `configs/template.m`).\n']);
            warning('on', 'backtrace');
        end
    else
        error('ROTARE:validateconfig:configNotFound', ...
              'The configuration file (''%s'') was not found.', configFile);
    end

    % ===========================================
    % Defaults and expected strings

    DEF.WATER_ALTITUDE = 0;  % This allows the plotting and analysis scripts to work

    DEF.NONDIM = {'US', 'EU'};
    DEF.VERBOSITY = {'min', 'all'};
    DEF.SOLVERS = {'leishman', 'indfact', 'indvel', 'stahlhut', 'all'};
    DEF.FLUID = {'air', 'seawater', 'freshwater'};
    DEF.LOSSES = {'none', 'hub', 'tip', 'both', 'all'};
    DEF.POLARS = {'polynomial', 'file'};
    DEF.PITCHREF = {'zerolift', 'chordline'};
    DEF.HUB_TYPE = {'none', 'cylinder', 'conic', 'blunted_conic', 'biconic', 'tangent_ogive', ...
                    'blunted_tangent_ogive', 'secant_ogive_regular', 'secant_ogive_bulge', ...
                    'elliptical', 'parabolic', 'power_series', 'lv_haack', 'vonkarman'};
    DEF.APPLI = {'helicopter', 'propeller', 'windturbine'};

    % ===========================================
    % Input checks

    Sim = checksim(Sim, configFile, DEF); % Simulation parameters
    Mod = checkmod(Mod, configFile, DEF); % Models, solvers, etc.
    Flow.fluid = validatestring(Flow.fluid, DEF.FLUID, configFile, 'Flow.fluid'); % Fluid
    Airfoil = checkairfoil(Airfoil, configFile, DEF); % Airfoils data

    Blade = checkblade(Blade, configFile, length(Airfoil), DEF); % Blade
    Op = checkop(Op, configFile, DEF, numel(Blade), Flow.fluid); % Operating points

    % ===========================================
    % Extra warnings
    if Sim.Warn.sonicTip
        for i = 1:numel(Blade)
            sonictip(Op, Blade(i));
        end
    end

end

% ==================================================================================================
% ==================================== Helper functions ============================================
% ==================================================================================================

function vallogical(var, configFile, varname)
    % VALLOGICAL Validates logical parameter
    validateattributes(var, {'logical'}, {'scalar'}, configFile, varname);
end

function valchar(var, configFile, varname)
    % VALCHAR Validates char parameter
    validateattributes(var, {'char', 'string'}, {'scalartext', 'nonempty'}, configFile, varname);
end

function file = ensurefileext(file, ext)
    import af_tools.utils.appendextension
    file = appendextension(file, ext);

end

% ==================================================================================================
% =============================== General simulation options =======================================
% ==================================================================================================
function Sim = checksim(Sim, configFile, DEF)

    % Autosave
    vallogical(Sim.Save.autosave, configFile, 'Sim.Save.autosave');
    vallogical(Sim.Save.overwrite, configFile, 'Sim.Save.overwrite');

    if Sim.Save.autosave
        try
            valchar(Sim.Save.dir, configFile, 'Sim.Save.dir');
            valchar(Sim.Save.filename, configFile, 'Sim.Save.filename');
        catch ME
            msg = ['Error for autosave: as Sim.Save.autosave = true, '...
                   'you must specify properly Sim.saveDir and Sim.Save.filename'];
            causeException = MException('ROTARE:validateconfig:invalidSaveResults', msg);
            ME = addCause(ME, causeException);
            rethrow(ME);
        end
    end

    vallogical(Sim.Save.appendInfo, configFile, 'Sim.Save.appendInfo');
    vallogical(Sim.Save.prependTime, configFile, 'Sim.Save.prependTime');

    % Outputs
    vallogical(Sim.Out.showPlots, configFile, 'Sim.Out.showPlots');
    vallogical(Sim.Out.show3D, configFile, 'Sim.Out.show3D');
    Sim.Out.hubType = validatestring(Sim.Out.hubType, DEF.HUB_TYPE, ...
                                     configFile, 'Sim.Out.hubType');
    vallogical(Sim.Out.console, configFile, 'Sim.Out.console');
    Sim.Out.verbosity = validatestring(Sim.Out.verbosity, DEF.VERBOSITY, ...
                                       configFile, 'Sim.Out.verbosity');

    % Warnings
    vallogical(Sim.Warn.sonicTip, configFile, 'Sim.Warn.sonicTip');

    % Miscellaneous
    Sim.Misc.nonDim = validatestring(Sim.Misc.nonDim, DEF.NONDIM, ...
                                     configFile, 'Sim.Misc.nonDim');
    Sim.Misc.appli = validatestring(Sim.Misc.appli, DEF.APPLI, ...
                                    configFile, 'Sim.Misc.app');
end

% ==================================================================================================
% ==================================== Models and solvers ==========================================
% ==================================================================================================
function Mod = checkmod(Mod, configFile, DEF)

    % Solvers
    Mod.solvers = cellstr(Mod.solvers);
    if any(strcmp(Mod.solvers, 'all'))
        Mod.solvers = DEF.SOLVERS(~strcmp(DEF.SOLVERS, 'all'));
    else
        for iSolv = 1:length(Mod.solvers)
            Mod.solvers{iSolv} = validatestring(Mod.solvers{iSolv}, DEF.SOLVERS, configFile, ...
                                                'Mod.solvers');
        end
    end

    % Extensions/corrections
    Mod.Ext.losses = validatestring(Mod.Ext.losses, DEF.LOSSES, configFile, 'Mod.Ext.losses');

    % Numerical parameters
    validateattributes(Mod.Num.convCrit, ...
                       {'double'}, ...
                       {'scalar', 'positive'}, ...
                       configFile, 'Mod.Num.convCrit');
    validateattributes(Mod.Num.maxIter, ...
                       {'double'}, ...
                       {'scalar', 'positive'}, ...
                       configFile, 'Mod.Num.maxIter');

end

% ==================================================================================================
% ===================================== Operating points ===========================================
% ==================================================================================================
function Op = checkop(Op, configFile, DEF, nRotors, fluid)

    validateattributes(Op.speed, ...
                       {'numeric'}, ...
                       {'vector', 'nonempty', 'nonnegative'}, ...
                       configFile, 'Op.speed');

    try
        validateattributes(Op.collective, ...
                           {'numeric'}, ...
                           {'3d', 'nonempty', 'nrows', nRotors}, ...
                           configFile, 'Op.collective');

        validateattributes(Op.rpm, ...
                           {'numeric'}, ...
                           {'3d', 'nonempty', 'positive', 'nrows', nRotors}, ...
                           configFile, 'Op.rpm');
    catch ME
        msg = ['Undefined operating conditions for additional rotors.\n' ...
               'The configuration file defined ', num2str(nRotors), ' rotors (using Blade '...
               'structure). '...
               'Therefore, the config variables ''Op.collective'' and ''Op.rpm'' must be '...
               'arrays whose rows correspond to the operating condition a different rotor.\n'...
               'See ''configs/templatecoax.m'' for an example of a valid coax configuration.'];
        causeException = MException('ROTARE:validateconfig:NotEnoughOperPoints', msg);
        ME = addCause(ME, causeException);
        rethrow(ME);
    end

    if strcmpi(fluid, 'air')
        validateattributes(Op.altitude, ...
                           {'numeric'}, ...
                           {'vector', 'nonempty'}, ...
                           configFile, 'Op.altitude');

    else
        Op.altitude = DEF.WATER_ALTITUDE;
    end
end

% ==================================================================================================
% ==================================== Airfoil parameters ==========================================
% ==================================================================================================
function Airfoil = checkairfoil(Airfoil, configFile, DEF)

    for i = 1:length(Airfoil)

        valchar(Airfoil(i).coordFile, configFile, 'Airfoil.coordFile');
        Airfoil(i).coordFile = ensurefileext(Airfoil(i).coordFile, '.dat');

        if ~isfile(Airfoil(i).coordFile)
            error('ROTARE:validateconfig:airfoilCoordFileNotFound', ...
                  ['The airfoil coordinates file was not found (%s).\n'...
                   'Please specify a valid coordinates file.\n'], ...
                  Airfoil(i).coordFile);
        end

        Airfoil(i).polarType = validatestring(Airfoil(i).polarType, DEF.POLARS, ...
                                              configFile, 'Airfoil.polarType');

        if strcmp(Airfoil(i).polarType, 'file')
            valchar(Airfoil(i).polarFile, configFile, 'Airfoil.polarFile');
            Airfoil(i).polarFile = ensurefileext(Airfoil(i).polarFile, '.mat');

            if ~isfile(Airfoil(i).polarFile)
                error('ROTARE:validateconfig:airfoilPolarFileNotFound', ...
                      ['The airfoil polar file was not found (%s).\n'...
                       'As Airfoil.polarType is ''file'', you must specify a valid polar file.'...
                       '\n See Airfoil.polarFile in %s.'], Airfoil(i).coordFile, configFile);
            end

            vallogical(Airfoil(i).extrap, configFile, 'Airfoil.extrap');

        else
            try
                validateattributes(Airfoil(i).clPoly, ...
                                   {'double'}, ...
                                   {'vector', 'nonempty'}, ...
                                   configFile, 'Airfoil.clPoly');
                validateattributes(Airfoil(i).cdPoly, ...
                                   {'double'}, ...
                                   {'vector', 'nonempty'}, ...
                                   configFile, 'Airfoil.cdPoly');
            catch ME
                msg = ['Error for polynomial expression of cl and cd:\n'...
                       'As Mod.polar = ''polynomial'', '...
                       'you must specify properly Blade.clPolyCoeff and Blade.cdPolyCoeff.\n' ...
                       'These coefficients are used as p1*x^(n-1) + p2*x^(n-2) + ... + pN.\n'...
                       'See <help polyval> for more information.'];
                causeException = MException('ROTARE:validateconfig:invalidPolynomialCoeffs', msg);
                ME = addCause(ME, causeException);
                rethrow(ME);
            end
        end
    end
end

% ==================================================================================================
% ================================= Blade and rotor geometry =======================================
% ==================================================================================================
function Blade = checkblade(Blade, configFile, nAirfoils, DEF)

    validateattributes(Blade, ...
                       {'struct'}, ...
                       {}, ...
                       configFile, 'Blade');

    for i = 1:numel(Blade)

        Blade(i).pitchRef = validatestring(Blade(i).pitchRef, DEF.PITCHREF, ...
                                           configFile, 'Blade.pitchRef');

        % Base dimensions
        validateattributes(Blade(i).nBlades, ...
                           {'numeric'}, ...
                           {'scalar', 'positive', 'integer'}, ...
                           configFile, 'Blade.nBlades');
        validateattributes(Blade(i).radius, ...
                           {'numeric'}, ...
                           {'vector', 'positive', 'increasing'}, ...
                           configFile, 'Blade.radius');

        if numel(Blade(i).radius) < 2
            error('ROTARE:validateconfig:notEnoughStations', ...
                  ['The blade geometry must specified with vectors of at least 2 elements' ...
                   ' (see Blade.radius).\n'...
                   'The first element corresponds to the blade root, the last one to the '...
                   'blade tip.']);
        end

        validateattributes(Blade(i).chord, ...
                           {'numeric'}, ...
                           {'vector', 'positive', 'size', size(Blade(i).radius)}, ...
                           configFile, 'Blade.chord');
        validateattributes(Blade(i).twist, ...
                           {'numeric'}, ...
                           {'vector', 'size', size(Blade(i).radius)}, ...
                           configFile, 'Blade.twist');
        validateattributes(Blade(i).iAirfoil, ...
                           {'numeric'}, ...
                           {'vector', 'positive', 'size', size(Blade(i).radius), 'integer', ...
                            '<=', nAirfoils}, ...
                           configFile, 'Blade.iAirfoil');

    end

    % Discretization
    validateattributes(Blade(i).nElem, ...
                       {'double'}, ...
                       {'scalar', 'positive'}, ...
                       configFile, 'Blade.nElem');
end

% ==================================================================================================
% ====================================== Extra warnings ============================================
% ==================================================================================================

function sonictip(Op, Blade)
    % SONICTIP Warns user that the input conditions will lead to transonic or supersonic tip speeds.

    MACH_LIMIT = 0.85;  % Limit to be considered transonic
    MACH_CRIT = 1.1;    % Mach limit to issue the critical warning
    RATIO_CRIT = 0.10;  % Ratio of blade above MACH_LIMIT to issue the critical warning

    omega = Op.rpm / 60 * 2 * pi;
    [~, vSound, ~, ~] = atmosisa(Op.altitude);

    % Find first rotation speed for which tip speed becomes problematic
    tipSpeed = omega * Blade.radius(end);
    tipMach = tipSpeed / vSound;
    idRPM = find(tipMach >= MACH_LIMIT, 1);

    if ~isempty(idRPM)
        % Find first element to encounter transonic flow at this speed
        elemRad = linspace(Blade.radius(1), Blade.radius(end), Blade.nElem);
        bladeSpeed = omega(idRPM) * elemRad;
        bladeMach = bladeSpeed / vSound;
        idElem = find(bladeMach >= MACH_LIMIT, 1);
        ratioSonicElem = (1 - idElem / Blade.nElem);

        if tipMach(idRPM) > MACH_CRIT || ratioSonicElem > RATIO_CRIT
            extraWarn = ['<strong>RESULTS ARE EXPECTED TO BE VERY UNRELIABLE FOR THESE ' ...
                         'SPEEDS!</strong>\n'];
        else
            extraWarn = '';
        end

        warning('off', 'backtrace');
        warning('ROTARE:validateconfig:transonictip', ...
                ['Possible transonic effects at the tip for '...
                 'speeds of %0.0f RPM and above.\n'...
                 'M_tip = %0.02f at %0.0f RPM (%0.1f %% of the blade will '...
                 'experience M > %0.2f).\n%s'], Op.rpm(idRPM), tipMach(idRPM), Op.rpm(idRPM), ...
                ratioSonicElem * 100, MACH_LIMIT, extraWarn);
        warning('on', 'backtrace');

    end

end
