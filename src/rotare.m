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

    if Sim.Out.console
        fprintf('Running Rotare with file %s\n\n', configFile);
    end

    % Construct objects
    Af = createairfoils(Uaf);
    for i = numel(Ublade):-1:1
        Rot(i) = Rotor(Ublade(i).nBlades, Af, Ublade(i).radius, Ublade(i).chord, ...
                       Ublade(i).twist, Ublade(i).iAirfoil, Ublade(i).nElem, Ublade(i).hubPos);
        Rot(i).name = Sim.Save.filename;
        Rot(i).pitchRef = Ublade(i).pitchRef;
        Rot(i).appli = Sim.Misc.appli;
        Rot(i).spinDir = Ublade(i).spinDir;
    end

    if Sim.Out.show3D
        Rot.plot('all', Sim.Out.hubType);
    end

    % (Following comment is so miss-hit metric checker stays happy)
    %| pragma Justify (metric, "cnest", "can't really be refactored");
    for iSolv = 1:length(Mod.solvers)
        Mod.solver = Mod.solvers{iSolv};

        printperfs(Sim.Out, 'hline');

        % ==========================================================================================
        % =================================== BEMT resolution ======================================
        % ==========================================================================================
        % Run the BEMT solver for each operation point given in the configuration

        % Number of operating points
        iOperPoint = 1; % Index of the current operating point

        for iAlt = 1:length(Uop.altitude)
            for iSpeed = 1:length(Uop.speed)
                for iRpm = 1:size(Uop.rpm, 2)
                    for iColl = 1:size(Uop.collective, 2)

                        tStart = tic; % Start timer for CPU time

                        for i = length(Rot):-1:1 % Reverse loop to improve pre-alloc

                            % Set current operating conditions and update fluid properties
                            Op(i) = Oper(Uop.altitude(iAlt), Uop.speed(iSpeed), ...
                                         Uop.rpm(i, iRpm), Uop.collective(i, iColl), Uflow.fluid);

                            % Instantiate operating rotor object
                            OpRot(iOperPoint, i) = OperRotor(Rot(i), Op(i));
                            OpRot(iOperPoint, i).nonDim = Sim.Misc.nonDim;
                        end
                        % Print current operating conditions in the console
                        printperfs(Sim.Out, 'header', Mod.solver, Op);

                        % Run BEMT solver
                        bemt(OpRot(iOperPoint, :), Mod);

                        % Keep track of CPU time for the solution
                        OpRot(iOperPoint, i).cpuTime =  toc(tStart);

                        iOperPoint = iOperPoint + 1;

                    end
                end
            end
        end

        if Sim.Out.console
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
                narginchk(4, 4);
                solver = varargin{1};
                Op = varargin{2};

                fprintf(['|| %8s || Altitude: %7.1f m  |  ' ...
                         'Speed: %5.1f m/s  |  ' ...
                         'RPM: %7.1f rpm  |  ' ...
                         'Collective: %4.01f deg\n'], ...
                        solver, Op(1).alt, Op(1).speed, Op(1).rpm, ...
                        rad2deg(Op(1).coll));

                for i = 2:numel(Op)
                    fprintf(['||          ||                      |  ' ...
                             '                  |  ' ...
                             '     %7.1f rpm  |  ' ...
                             '            %4.01f deg\n'], ...
                            Op(i).rpm, rad2deg(Op(i).coll));
                end
                fprintf(['||          ||                      |  ' ...
                         '                  |  ' ...
                         '                  |\n']);

            case 'results'

            case 'hline'
                fprintf('=============================================================');
                fprintf('========================================\n');

            otherwise
                error('ROTARE:printperfs:UnknownType', ...
                      'Type must be ''header'' or ''results''. Found %s', type);
        end
    end

end
