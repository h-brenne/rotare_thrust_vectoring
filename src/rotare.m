function [OpRot] = rotare(configFile)
    % ROTARE A feature-rich and open source implementation of the BEMT.
    %   This code is an implementation of the Blade Element Momentum Theory (BEMT) used for the
    %   analysis of all all kinds of rotors.
    %
    %   This software calculates the thrust, power and torque of any given rotor (helicopter,
    %   propeller, wind or tidal turbine, etc) over a range of operating points. Various solvers are
    %   implemented and a few corrections/extensions to the base equations are also possible.
    %
    %   A full documentation for the software can be found on:
    %   <a href="https://gitlab.uliege.be/thlamb/rotare-doc">ULiege's Gitlab instance</a>.
    % -----
    %
    %   The Rotare function acts as a wrapper for the main BEMT solver. It loads the configuration
    %   file, then executes the pre-processing functions, and finally runs the BEMT main solver in a
    %   loop for all design points. The last step is a call for the post-processing and analysis
    %   functions.
    %
    % Usage:
    %   1. Create a configuration file based on `configs/template.m`.
    %   2. Use that as input argument for Rotare: ROTARE('configs/yourconfig.m')
    %        or
    %      Run ROTARE() without argument and manually select the configuration file to load.
    % -----
    %
    % Syntax:
    %   rotare() prompts the user to select a configuration file and then execute Rotare based on
    %   the loaded file.
    %
    %   rotare(configFile) runs Rotare directly based on the parameters specified in the file
    %   `configFile`.
    %
    % Inputs:
    %   configFile: Path of the configuration file.
    %
    % See also: bemt, template.
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

    % Cleanup, imports and environment setting
    clearvars -except configFile;
    close all;
    clc;
    addpath(genpath('.'));

    verifyinstall; % Check if packages (libs) and required functions are presents on the system

    % Import packages
    import af_tools.*

    % ==============================================================================================
    % ==================================== Pre-processing ==========================================
    % ==============================================================================================

    % If no input configuration, ask user to select one manually
    if nargin == 0
        [filename, path] = uigetfile('configs/*.m', 'Select a configuration file');
        configFile = fullfile(path, filename);
        clear filename path;
    end

    % Validate the config file and load the sanitized structures
    [Sim, Mod, Uflow, Uop, Uaf, Ublade] = validateconfig(configFile);

    % Construct objects
    Af = createairfoils(Uaf);
    Rot = Rotor(Ublade.nBlades, Af, Ublade.radius, Ublade.chord, Ublade.twist, Ublade.iAirfoil, ...
                Ublade.nElem);
    Rot.name = Sim.Save.filename;
    Rot.pitchRef = Ublade.pitchRef;
    Rot.appli = Sim.Misc.appli;

    if Sim.Out.show3D
        Rot.plot('all', Sim.Out.hubType);
    end

    % (Following comment is so miss-hit metric checker stays happy)
    %| pragma Justify (metric, "cnest", "can't really be refactored");
    for iSolv = 1:length(Mod.solvers)
        Mod.solver = Mod.solvers{iSolv};

        % ==========================================================================================
        % =================================== BEMT resolution ======================================
        % ==========================================================================================
        % Run the BEMT solver for each operation point given in the configuration

        % Number of operating points
        iOperPoint = 1; % Index of the current operating point

        for iAlt = 1:length(Uop.altitude)
            for iSpeed = 1:length(Uop.speed)
                for iRpm = 1:length(Uop.rpm)
                    for iColl = 1:length(Uop.collective)

                        tStart = tic; % Start timer for CPU time

                        % Set current operating conditions and update fluid properties
                        Op = Oper(Uop.altitude(iAlt), Uop.speed(iSpeed), Uop.rpm(iRpm), ...
                                  Uop.collective(iColl), Uflow.fluid);

                        % Print current operating conditions in the console
                        printperfs(Sim.Out, 'header', ...
                                   Mod.solver, Op.alt, Op.speed, Op.rpm, Op.coll);

                        % Instantiate operating rotor object
                        for i = length(Rot):-1:1 % Reverse loop to improve pre-alloc
                            OpRot(i, iOperPoint) = OperRotor(Rot(i), Op);
                            OpRot(i, iOperPoint).nonDim = Sim.Misc.nonDim;
                        end

                        % Run BEMT solver
                        bemt(OpRot(:, iOperPoint), Mod);

                        % Keep track of CPU time for the solution
                        OpRot(i, iOperPoint).cpuTime =  toc(tStart);

                        iOperPoint = iOperPoint + 1;

                    end
                end
            end
        end

        if Sim.Out.console
            disp('=============');
            disp(' ');
        end

        % Save solution to MAT-file for future reusability
        if Sim.Save.autosave
            TmpStruct.OpRot = OpRot;
            saveresults(TmpStruct, Sim.Save, Mod);
            clear TmpStruct;
        end

    end
    % ==============================================================================================
    % ====================================== Analysis ==============================================
    % ==============================================================================================

    % [TODO]
    %   - Display main the results (T (CT), P (CP), Q(CQ), eff) for each case as a table
    %   - Plot results summary in terms of CT and CP for all operating points

end

function printperfs(Opts, type, varargin)
    % printperfs Print rotor performance for every operating point.

    if Opts.console
        switch type
            case 'header'
                narginchk(7, 7);
                fprintf(['|| %s || Altitude: %0.1f m  |  ' ...
                         'Speed: %0.1f m/s  |  ' ...
                         'RPM: %0.01f rpm  |  ' ...
                         'Collective: %0.01f deg\n\n'], ...
                        varargin{1}, varargin{2}, varargin{3}, varargin{4}, rad2deg(varargin{5}));

            case 'results'
            otherwise
                error('ROTARE:printperfs:UnknownType', ...
                      'Type must be ''header'' or ''results''. Found %s', type);
        end
    end

end
